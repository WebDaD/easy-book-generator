# Easy Book Generator

Helps you to create a book from a collection of markdown files.

## Installation

```bash
git clone
cd easy-book-generator
ln -s $PWD/ebg.sh /usr/local/bin/ebg
chmod +x /usr/local/bin/ebg
```

## Usage

```bash
ebg
```

### Create a new book

```bash
ebg init
```

### Add a new part

```bash
ebg add part
```

### Add a new chapter

```bash
ebg add chapter PART
```

### Build the book

```bash
ebg build book
```

### Build the expose

```bash
ebg build expose
```
