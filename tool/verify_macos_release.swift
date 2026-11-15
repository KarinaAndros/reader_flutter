import CryptoKit
import Darwin
import Foundation

// Verify with the app's public key, without requesting the private signing key.
// The signed feed prefix follows Sparkle's SPUExtractSignedFeed.m format.
enum VerificationError: Error { case invalid(String) }
func require(_ condition: Bool, _ message: String) throws {
  if !condition { throw VerificationError.invalid(message) }
}

do {
  let args = CommandLine.arguments
  try require(args.count == 4, "Usage: verify_macos_release.swift Info.plist appcast.xml archive.zip")
  let plistData = try Data(contentsOf: URL(fileURLWithPath: args[1]))
  let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
  guard let encodedKey = plist?["SUPublicEDKey"] as? String,
        let keyData = Data(base64Encoded: encodedKey),
        let version = plist?["CFBundleShortVersionString"] as? String,
        let build = plist?["CFBundleVersion"] as? String else {
    throw VerificationError.invalid("Missing app public key or version")
  }
  let key = try Curve25519.Signing.PublicKey(rawRepresentation: keyData)
  let feed = try Data(contentsOf: URL(fileURLWithPath: args[2]))
  let marker = Data("<!-- sparkle-signatures:\n".utf8)
  guard let range = feed.range(of: marker, options: .backwards),
        let end = feed.range(of: Data("-->".utf8), in: range.upperBound..<feed.endIndex),
        let footer = String(data: feed[range.upperBound..<end.lowerBound], encoding: .utf8) else {
    throw VerificationError.invalid("Missing feed signature")
  }
  let content = Data(feed[..<range.lowerBound])
  let fields = footer.split(separator: "\n").reduce(into: [String: String]()) { result, line in
    let parts = line.split(separator: ":", maxSplits: 1)
    if parts.count == 2 {
      result[String(parts[0])] = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }
  guard let encodedSignature = fields["edSignature"],
        let signature = Data(base64Encoded: encodedSignature) else {
    throw VerificationError.invalid("Invalid feed signature encoding")
  }
  try require(Int(fields["length"] ?? "") == content.count, "Feed length mismatch")
  try require(key.isValidSignature(signature, for: content), "Feed signature verification failed")

  let xml = try XMLDocument(data: content)
  let namespace = "http://www.andymatuschak.org/xml-namespaces/sparkle"
  let items = try xml.nodes(forXPath: "/rss/channel/item")
  try require(items.count == 1, "Expected a single release")
  guard let item = items.first as? XMLElement,
        let enclosure = item.elements(forName: "enclosure").first,
        let archiveSignatureString = enclosure.attribute(forLocalName: "edSignature", uri: namespace)?.stringValue,
        let archiveSignature = Data(base64Encoded: archiveSignatureString) else {
    throw VerificationError.invalid("Missing archive signature")
  }
  try require(item.elements(forLocalName: "version", uri: namespace).first?.stringValue == build,
              "Feed build does not match the app")
  try require(item.elements(forLocalName: "shortVersionString", uri: namespace).first?.stringValue == version,
              "Feed version does not match the app")
  let archiveURL = URL(fileURLWithPath: args[3])
  let expectedURL = "https://github.com/KarinaAndros/reader_flutter/releases/download/v\(version)/\(archiveURL.lastPathComponent)"
  try require(enclosure.attribute(forName: "url")?.stringValue == expectedURL, "Unexpected download URL")
  let archive = try Data(contentsOf: archiveURL, options: .mappedIfSafe)
  try require(Int(enclosure.attribute(forName: "length")?.stringValue ?? "") == archive.count,
              "Archive length mismatch")
  try require(key.isValidSignature(archiveSignature, for: archive), "Archive signature verification failed")
  print("Verified appcast and archive for MYB \(version) (\(build)) using the app public key.")
} catch {
  FileHandle.standardError.write(Data("Verification failed: \(error)\n".utf8))
  exit(1)
}
