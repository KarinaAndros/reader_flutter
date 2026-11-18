package main

import "database/sql"

func loadBooks(db *sql.DB) ([]Book, error) {
	rows, err := db.Query(`
		SELECT id, title, author, genre, COALESCE(link, '')
		FROM books
		ORDER BY id
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	books := []Book{}

	for rows.Next() {
		var book Book

		err := rows.Scan(
			&book.ID,
			&book.Title,
			&book.Author,
			&book.Genre,
			&book.Link,
		)

		if err != nil {
			return nil, err
		}

		books = append(books, book)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return books, nil
}

func findBooks(db *sql.DB, id string) (Book, error) {
	var book Book

	err := db.QueryRow(`
		SELECT id, title, author, genre, COALESCE(link, '')
		FROM books
		WHERE id = ?
	`, id).Scan(
		&book.ID,
		&book.Title,
		&book.Author,
		&book.Genre,
		&book.Link,
	)

	return book, err
}
