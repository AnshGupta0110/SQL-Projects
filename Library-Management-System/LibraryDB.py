import streamlit as st
import sqlite3
import pandas as pd

# Database Connection
def connect_db():
    conn = sqlite3.connect("LibraryDB.sql")  # Change filename if needed
    return conn

# Function to fetch data
def fetch_data(query):
    conn = connect_db()
    df = pd.read_sql_query(query, conn)
    conn.close()
    return df

# Function to execute INSERT/UPDATE/DELETE
def execute_query(query, params=()):
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute(query, params)
    conn.commit()
    conn.close()

# Streamlit UI
st.title("Library Management System")
menu = ["View Books", "Add Book", "Update Book", "Delete Book"]
choice = st.sidebar.selectbox("Select Operation", menu)

if choice == "View Books":
    st.subheader("Library Books")
    query = "SELECT * FROM Books"  # Change based on your schema
    df = fetch_data(query)
    st.dataframe(df)

elif choice == "Add Book":
    st.subheader("Add a New Book")
    book_id = st.text_input("Book ID")
    title = st.text_input("Title")
    author = st.text_input("Author")
    if st.button("Add Book"):
        query = "INSERT INTO Books (BookID, Title, Author) VALUES (?, ?, ?)"
        execute_query(query, (book_id, title, author))
        st.success("Book Added Successfully")

elif choice == "Update Book":
    st.subheader("Update Book Details")
    book_id = st.text_input("Enter Book ID to Update")
    new_title = st.text_input("New Title")
    new_author = st.text_input("New Author")
    if st.button("Update Book"):
        query = "UPDATE Books SET Title = ?, Author = ? WHERE BookID = ?"
        execute_query(query, (new_title, new_author, book_id))
        st.success("Book Updated Successfully")

elif choice == "Delete Book":
    st.subheader("Delete a Book")
    book_id = st.text_input("Enter Book ID to Delete")
    if st.button("Delete Book"):
        query = "DELETE FROM Books WHERE BookID = ?"
        execute_query(query, (book_id,))
        st.success("Book Deleted Successfully")

st.sidebar.info("LibraryDB Streamlit App")
