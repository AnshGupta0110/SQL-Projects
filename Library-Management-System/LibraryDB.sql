-- Creating database LibraryDB for Library Management System
CREATE DATABASE LibraryDB;
USE LibraryDB;



-- Books Table 
-- Creating Books Table which stores information about books in the library.

CREATE TABLE Books (
    book_id INT IDENTITY(1,1) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    published_year DATE NOT NULL,
    is_available BIT DEFAULT '1'  -- '1' repersent TRUE
);


-- Members Table
-- Creating Members Table which consists informtion about library members

CREATE TABLE Members (
     member_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	 name VARCHAR(255) NOT NULL,
	 email VARCHAR(255),
	 phone_number VARCHAR(15),
	 join_date DATE DEFAULT (CAST(GETDATE() AS DATE))
);


-- Librarians Table
-- Creating Librarians Table which hold information or details of librarians.

CREATE TABLE Librarians (
       librarian_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	   name VARCHAR(255)NOT NULL,
	   email VARCHAR(255),
	   phone_number VARCHAR(15),
	   hire_date DATE DEFAULT (CAST(GETDATE() AS DATE))
);



--Borrowing Table
-- Borrowing Table stores borrowing records of members.

CREATE TABLE Borrowing(
     loan_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	 book_id INT,
	 member_id INT,
	 borrow_date DATE DEFAULT (CAST(GETDATE() AS DATE)),
	 return_date DATE,
	 librarian_id INT,
	 FOREIGN KEY (book_id) REFERENCES Books(book_id),
	 FOREIGN KEY (member_id) REFERENCES Members(member_id),
	 FOREIGN KEY (librarian_id) REFERENCES Librarians(librarian_id)
);




-- Inserting Data into each tables 

-- Insert data into Books table
INSERT INTO Books (title, author, genre, published_year, is_available)
VALUES 
('To Kill a Mockingbird', 'Harper Lee', 'Fiction', '1960-07-11', 1),
('1984', 'George Orwell', 'Dystopian', '1949-06-08', 1),
('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', '1925-04-10', 0),
('Moby Dick', 'Herman Melville', 'Adventure', '1851-10-18', 1),
('Pride and Prejudice', 'Jane Austen', 'Romance', '1813-01-28', 1);




-- Insert records into Members Table
INSERT INTO Members (name, email, phone_number)
VALUES 
('Alice Johnson', 'alice.johnson@example.com', '1234567890'),
('Bob Smith', 'bob.smith@example.com', '9876543210'),
('Charlie Brown', 'charlie.brown@example.com', '4567891230'),
('Diana Prince', 'diana.prince@example.com', '3216549870'),
('Eve Adams', 'eve.adams@example.com', '7891234560');




-- Inserting data into Librarians Table
INSERT INTO Librarians (name, email, phone_number)
VALUES 
('Laura Wilson', 'laura.wilson@library.com', '5551234567'),
('Michael Carter', 'michael.carter@library.com', '5559876543'),
('Emma Thomas', 'emma.thomas@library.com', '5554567891');




/* Basic functionalities:

1 - Add books, members, and borrowing transactions.
2 - Track books that are available or borrowed.
3 - Track loan history for members.



Writing Queries for Functionality: */






-- Query-1: Borrow a Book (Insert into Borrowing Table and Update Book Availability)
-- Making it reuseble and automated by using store procedure
-- Inserting a new record into the Borrowing table
CREATE PROCEDURE BorrowBookSafe
    @book_id INT,
    @member_id INT,
    @librarian_id INT
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Check book availability
        IF EXISTS (SELECT 1 FROM Books WHERE book_id = @book_id AND is_available = 1)
        BEGIN
            -- Insert into Borrowing
            INSERT INTO Borrowing (book_id, member_id, librarian_id, borrow_date)
            VALUES (@book_id, @member_id, @librarian_id, CAST(GETDATE() AS DATE));

            -- Mark book as unavailable
            UPDATE Books
            SET is_available = 0
            WHERE book_id = @book_id;

            COMMIT TRANSACTION;
            PRINT 'Book borrowed successfully.';
        END
        ELSE
        BEGIN
            PRINT 'Book is not available.';
            ROLLBACK TRANSACTION;
        END
    END TRY

    BEGIN CATCH
        PRINT 'An error occurred.';
        ROLLBACK TRANSACTION;
    END CATCH
END;

EXEC BorrowBook @book_id = 2, @member_id = 3, @librarian_id = 2;








-- Query-2: Return a Book (Update Return Date and Book Availability)

-- updating borrowing table's return_date with when borrowed book return to library.
-- "CAST(GETDATE() AS date)" will return date when the update is made in table 
-- Making it Automated and reuseble by store procedure  
CREATE PROCEDURE ReturnBooks
    @loan_id INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
	IF EXISTS (SELECT 1 FROM Borrowing WHERE loan_id = @loan_id AND return_date IS NULL)
	BEGIN
	    UPDATE Borrowing
        SET return_date = CAST(GETDATE() AS date)
        WHERE loan_id = @loan_id;

		COMMIT TRANSACTION;
        PRINT 'Book returned successfully.';
    END
    ELSE
    BEGIN
            PRINT 'Book is not available.';
            ROLLBACK TRANSACTION;
    END
END TRY
BEGIN CATCH
        PRINT 'An error occurfor red.';
        ROLLBACK TRANSACTION;
END CATCH
END;

EXEC ReturnBooks @loan_id = 4;


-- Using Trigger for update Books availability automatically 
CREATE TRIGGER UpdateBookAvailability
ON Borrowing
AFTER UPDATE
AS
BEGIN
    -- Check if the return_date was updated and the loan_id has a non-NULL return_date
    IF UPDATE(return_date)
    BEGIN
        DECLARE @book_id INT;

        -- Get the book_id from the updated row in Borrowing table
        SELECT @book_id = book_id FROM INSERTED WHERE return_date IS NOT NULL;

        -- Update the is_available column in the Books table
        UPDATE Books
        SET is_available = 1
        WHERE book_id = @book_id;
    END
END;




-- Query 3 - Check Available Books
SELECT * FROM Books
WHERE is_available = 1;






-- Query 4 - View Member Loan History
CREATE PROCEDURE GetMemberBorrowingDetails
    @member_id INT
AS
BEGIN
    SELECT m.name, m.phone_number, b.book_id, b.title, br.borrow_date, br.return_date
    FROM Members m
    JOIN Borrowing br ON m.member_id = br.member_id
    JOIN Books b ON br.book_id = b.book_id
    WHERE m.member_id = @member_id;
END;

EXEC GetMemberBorrowingDetails @member_id = 3;







-- Qurey 5 - List Overdue Books
SELECT m.name, b.title, br.borrow_date
FROM Members m 
JOIN Borrowing br ON m.member_id = br.member_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.return_date IS NULL AND br.borrow_date < DATEADD(DAY, -15, GETDATE())



-- Query 6 - List All Books by a Specific Author
SELECT title, genre, published_year
FROM Books
WHERE author = 'Jane Austen';



-- Query 7 - Find Books Published After a Certain Year
SELECT title,author, published_year
FROM Books
WHERE published_year > '1900';




-- Query 8 - Count Total Books in Library 
SELECT COUNT(*) AS total_book
FROM Books;




-- Query 9 - View All Members Who Borrowed a Specific Book
SELECT m.name, br.borrow_date, br.return_date
FROM Members m 
JOIN Borrowing br ON m.member_id = br.member_id
JOIN Books b ON br.book_id = b.book_id
WHERE b.title = 'To Kill a Mockingbird';



-- Query 10 - Find Borrowing History of a Specific Member
SELECT b.title, br.borrow_date, br.return_date
FROM Borrowing br JOIN Books b ON br.book_id = b.book_id
WHERE br.member_id = 1;





-- Query 11 - List all Available Books of a Specific Genre
SELECT title, author, published_year
FROM Books
WHERE genre = 'Romance' AND is_available = 1;




-- Query 12 - Calculate the Total Number of books Borrowed by each member
SELECT m.name, COUNT(br.loan_id) AS NumberofBooks
FROM Members m JOIN Borrowing br ON m.member_id = br.member_id
GROUP BY m.name;




-- Query 13 - List All Overdue Books Not Yet Returned
SELECT m.name, b.title, br.borrow_date
FROM Members m 
JOIN Borrowing br ON m.member_id = br.member_id
JOIN Books b ON br.book_id = b.book_id
WHERE return_date IS NULL AND br.borrow_date < DATEADD(DAY, -30, GETDATE());




-- Query 14 - List the Librarians Who Processed the Most Borrowings
SELECT l.name, COUNT(br.book_id) as totalborrowing
FROM Librarians l JOIN Borrowing br ON l.librarian_id = br.librarian_id
GROUP BY l.name 
ORDER BY totalborrowing DESC;




-- Query 15 - Find all books borrowed but not yet returned
SELECT m.name, b.title, br.borrow_date
FROM Members m 
JOIN Borrowing br ON m.member_id = br.member_id
JOIN Books b ON br.book_id = b.book_id
WHERE return_date IS NULL 




-- Query 16 - Find the most borrowed books

SELECT TOP 5 b.title, COUNT(br.book_id) AS borrow_count
FROM Borrowing br JOIN Books b ON br.book_id = b.book_id
GROUP BY b.title
ORDER BY borrow_count DESC;





-- Query 17 - Find Books That Have Never Been Borrowed

SELECT b.title
FROM Books b
LEFT JOIN Borrowing br ON b.book_id = br.book_id
WHERE br.book_id IS NULL;




-- Query 18 - Create View of Borrowed Books for reporting.
CREATE VIEW BorrowedBooksView AS
SELECT b.title, m.name AS borrowed_by, br.borrow_date, br.return_date
FROM Borrowing br
JOIN Books b ON br.book_id = b.book_id
JOIN Members m ON br.member_id = m.member_id;


SELECT * FROM BorrowedBooksView