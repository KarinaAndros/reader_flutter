package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"

	_ "modernc.org/sqlite"
)

func main() {
	db, err := sql.Open("sqlite", "myb.db")
	if err != nil {
		fmt.Println("Ошибка открытия бд:", err)
		return
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		fmt.Println("Ошибка подключения бд:", err)
		return
	}

	fmt.Println("БД подключена")

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS books (
			id TEXT PRIMARY KEY NOT NULL,
			title TEXT NOT NULL,
			author TEXT NOT NULL,
			genre TEXT NOT NULL,
			link TEXT NULL
		)
	`)

	if err != nil {
		fmt.Println("Не удалось создать таблицу books")
		return
	}

	_, err = db.Exec(`
		INSERT INTO books (id, title, author, genre, link)
		VALUES (?, ?, ?, ?, ?)
		ON CONFLICT(id) DO NOTHING
	`,
		"kashtanka",
		"Каштанка",
		"Антон Чехов",
		"Рассказ",
		"http://old.liblermont.ru/warbook/src/pdf/child/4.pdf",
	)

	if err != nil {
		fmt.Println("Не удалось добавить книгу:", err)
		return
	}

	var title, author string

	err = db.QueryRow(
		"SELECT title, author FROM books WHERE id = ?",
		"kashtanka",
	).Scan(&title, &author)

	if err != nil {
		fmt.Println("Не удалось прочитать книгу:", err)
		return
	}

	fmt.Println("Название из базы:", title)
	fmt.Println("Автор:", author)

	fmt.Println("Таблица books создана")

	http.HandleFunc("GET /books", func(w http.ResponseWriter, r *http.Request) {
		books, err := loadBooks(db)
		if err != nil {
			fmt.Println("Ошибка чтения каталога:", err)
			http.Error(w, "Не удалось загрузить каталог", http.StatusInternalServerError)
			return
		}

		genre := r.URL.Query().Get("genre")
		query := strings.ToLower(r.URL.Query().Get("q"))

		filtered := []Book{}

		for _, book := range books {
			matchesGenre := genre == "" || book.Genre == genre
			matchesTitle := strings.Contains(
				strings.ToLower(book.Title),
				query,
			)
			mathesAuthor := strings.Contains(
				strings.ToLower(book.Author),
				query,
			)

			if matchesGenre && (matchesTitle || mathesAuthor) {
				filtered = append(filtered, book)
			}
		}

		data, err := json.MarshalIndent(filtered, "", "  ")
		if err != nil {
			http.Error(w, "Ошибка преобразования книг", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.Write(data)
	})

	http.HandleFunc("GET /books/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")

		book, err := findBooks(db, id)

		if errors.Is(err, sql.ErrNoRows) {
			http.Error(w, "Книга не найдена", http.StatusNotFound)
			return
		}

		if err != nil {
			fmt.Println("Ошибка чтения книги:", err)
			http.Error(w, "Не удалось загрузить книгу", http.StatusInternalServerError)
			return
		}

		data, err := json.MarshalIndent(book, "", "  ")
		if err != nil {
			http.Error(w, "Ошибка преобразования книги", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.Write(data)
	})

	listenAddress := os.Getenv("BOOKS_LISTEN_ADDR")
	if listenAddress == "" {
		listenAddress = ":8080"
	}
	fmt.Printf("Сервер MYB слушает %s; каталог: /books\n", listenAddress)

	err = http.ListenAndServe(listenAddress, nil)
	if err != nil {
		fmt.Println("Ошибка сервера:", err)
	}

}
