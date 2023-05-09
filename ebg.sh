#!/bin/bash
TEMP_DIR="/tmp"


# functions

get_string() {
  local org_arg="$1"
  local name="$2"
  local str=""

  # Check if argument exists and is not empty
  if [ -n "$org_arg" ]; then
    str="$org_arg"
  else
    # Prompt user for input
    read -p "Please enter $name: " str
  fi

  echo "$str"
}
slugify() {
  # Convert string to lowercase
  slug=$(echo "$1" | tr '[:upper:]' '[:lower:]')

  # Replace spaces and underscores with hyphens
  slug=$(echo "$slug" | sed 's/[[:space:]_]/-/g')

  # Remove all characters except letters, numbers, and hyphens
  slug=$(echo "$slug" | sed 's/[^[:alnum:]-]//g')

  echo "$slug"
}

init_file() {
  filename="$1"
  todo_text="$2"

  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$filename")"

  # Check if file exists, and if not, create it with YAML front matter
  if [ ! -f "$filename" ]; then
    echo '---' > "$filename"
    echo 'tag: todo' >> "$filename"
    echo '---' >> "$filename"
    echo '' >> "$filename"
  fi

  # Add TODO item to file
  echo "TODO: $todo_text" >> "$filename"
}

init_expose() {
  filename="expose/_expose.md"
  title="$1"
  echo '---' > "$filename"
  echo 'tag: todo' >> "$filename"
  echo '---' >> "$filename"
  echo '' >> "$filename"
  echo "# $title" >> "$filename"
  echo '' >> "$filename"
  echo '## Overview' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/overview.md' >> "$filename"
  echo '' >> "$filename"
  echo '## Key Features' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/key_features.md' >> "$filename"
  echo '' >> "$filename"
  echo '## Target Audience' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/target_audience.md' >> "$filename"
  echo '' >> "$filename"
  echo '## Selling Points' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/selling_points.md' >> "$filename"
  echo '' >> "$filename"
  echo '## Similar Books' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/similar_books.md' >> "$filename"
  echo '' >> "$filename"
  echo '## About the Author' >> "$filename"
  echo '' >> "$filename"
  echo '!include book/about_the_author.md' >> "$filename"
  echo '' >> "$filename"
  echo '## Text Sample' >> "$filename"
  echo '' >> "$filename"
  echo 'TODO: add a text sample' >> "$filename"
  echo '' >> "$filename"
}
build_expose() {
  expose_tmp="${TEMP_DIR}/expose.md"
  # combine all the markdown files into one
  perl -ne 's/^\!include\s(.+)$/`cat /$1`/e;print' expose/_expose.md > "$expose_tmp"

  # remove all tags from the markdown
  perl -pi -e 's/---//g' "$expose_tmp"
  perl -pi -e 's/^tag(.+)$//g' "$expose_tmp"

  # combine triple new lines into one
  perl -pi -e 's/\n\n\n/\n\n/g' "$expose_tmp"

  # remove all new lines at the beginning of the file
  perl -pi -e 's/^\n//g' "$expose_tmp"

  # remove all new lines at the end of the file
  perl -pi -e 's/\n$//g' "$expose_tmp"

  # convert to pdf
  pandoc "$expose_tmp" -o "export/expose.pdf"

  # try to open file in preview
  open "export/expose.pdf"
}
build_book() {
  extension=$1
  book_tmp="${TEMP_DIR}/book.md"
  # combine all the markdown files into one
  perl -ne 's/^\!include\s(.+)$/`cat /$1`/e;print' book/_toc.md > "$book_tmp"

  # remove all tags from the markdown
  perl -pi -e 's/---//g' "$book_tmp"
  perl -pi -e 's/^tag(.+)$//g' "$book_tmp"

  # combine triple new lines into one
  perl -pi -e 's/\n\n\n/\n\n/g' "$book_tmp"

  # remove all new lines at the beginning of the file
  perl -pi -e 's/^\n//g' "$book_tmp"

  # remove all new lines at the end of the file
  perl -pi -e 's/\n$//g' "$book_tmp"

  # convert to pdf
  pandoc "$book_tmp" -o "export/book.$extension"

  # try to open file in preview
  open "export/book.$extension"
}


# Define usage message
usage() {
  echo "Usage: ebg <command> [options]"
  echo "Commands:"
  echo "  init [title]  - initialize a new book, optionally with a title"
  echo "  add           - add something new to the book"
  echo "    part [title]- add a new part. Optionally with a title"
  echo "    chapter <part> [title]    - add a new chapter in the current or given part, optionally with a title"
  echo "  build         - build the book or other artifacts"
  echo "    expose      - build the expose"
  echo "    book [extension] - build the book, optionally with a file extension (pdf, epub, html, etc.) Default is pdf"
  exit 10
}

# check if pandoc is installed
if ! command -v pandoc >/dev/null 2>&1 ; then
  echo "Error: Pandoc is not installed. Please install Pandoc before continuing."
  exit 1
fi

# Check for command argument
if [ -z "$1" ]; then
  usage
fi

# Handle commands
case "$1" in
  init)
    TITLE=$(get_string "$2" "book title")
    TITLE_SLUG=$(slugify "$TITLE")
    echo "Initializing new book with title $TITLE..."
    # perform initialization logic
    mkdir -p "$TITLE_SLUG"
    cd "$TITLE_SLUG" || exit 1 # exit if cd fails
    mkdir -p book
    mkdir -p expose
    mkdir -p export
    mkdir -p marketing

    touch book/_toc.md

    init_file "expose/key_features.md" "Write key features"
    init_file "expose/overview.md" "Write short overview"
    init_file "expose/selling_points.md" "Write up some selling points"
    init_file "expose/similar_books.md" "Write about similar books"
    init_file "expose/target_audience.md" "Write about the target audience"
    init_expose "$TITLE"

    init_file "marketing/copy.md" "Write marketing copy"

    touch .gitignore
    echo "export" >> .gitignore

    touch metadata.yaml
    echo "title: $TITLE" >> metadata.yaml
    echo "title_slug: $TITLE_SLUG" >> metadata.yaml
    echo "author: TODO" >> metadata.yaml

    echo "Done. Now run 'ebg add part' to add a part to the book."
    echo "Also check for any TODOs in the files."
    echo "Then run 'ebg build book' to build the book and 'ebg build expose' to build the expose."
    ;;
  add)
    case "$2" in
      part)
        PART_TITLE=$(get_string "$3" "part title")
        PART_TITLE_SLUG=$(slugify "$PART_TITLE")
        echo "Adding new part with title $PART_TITLE..."
        # perform add logic
        mkdir -p "book/$PART_TITLE_SLUG"
        touch "book/$PART_TITLE_SLUG/_toc.md"
        echo '---' > "book/$PART_TITLE_SLUG/_toc.md"
        echo 'tag: todo' >> "book/$PART_TITLE_SLUG/_toc.md"
        echo '---' >> "book/$PART_TITLE_SLUG/_toc.md"
        echo '' >> "book/$PART_TITLE_SLUG/_toc.md"
        echo "" >> "book/_toc.md"
        echo "# $PART_TITLE" >> "book/_toc.md"
        echo "" >> "book/_toc.md"
        echo "!include book/$PART_TITLE_SLUG/_toc.md" >> book/_toc.md
        echo "" >> "book/_toc.md"
        echo "Done. Now run 'ebg add chapter' to add a chapter to the part."
        ;;
      chapter)
        # must be in a part folder or part is specified via slug
        if [[ "$(basename "$(pwd)")" != "book" || ! -f "_toc.md" ]]; then
          echo "Error: You are not in a part folder under the 'book' directory. Please change to a part folder or specify the part slug as the third argument."
          exit 1
        elif [[ -z "$3" ]]; then
          echo "Error: You are not in a part folder under the 'book' directory. Please change to a part folder or specify the part slug as the third argument."
          exit 1
        elif [[ ! -d "$3" ]]; then
          echo "Error: Folder '$3' does not exist under the 'book' directory."
          exit 1
        else
          PART="${3:-$(basename "$(pwd)")}"
        fi
        CHAPTER_TITLE=$(get_string "$4" "chapter title")
        CHAPTER_TITLE_SLUG=$(slugify "$CHAPTER_TITLE")
        echo "Adding new chapter with title $CHAPTER_TITLE to part $PART..."
        # perform add logic
        touch "book/$PART/$CHAPTER_TITLE_SLUG.md"
        echo '---' > "book/$PART/$CHAPTER_TITLE_SLUG.md"
        echo 'tag: todo' >> "book/$PART/$CHAPTER_TITLE_SLUG.md"
        echo '---' >> "book/$PART/$CHAPTER_TITLE_SLUG.md"
        echo '' >> "book/$PART/$CHAPTER_TITLE_SLUG.md"
        echo "" >> "book/$PART/_toc.md"
        echo "## $CHAPTER_TITLE" >> "book/$PART/_toc.md"
        echo "" >> "book/$PART/_toc.md"
        echo "!include book/$PART/$CHAPTER_TITLE_SLUG.md" >> "book/$PART/_toc.md"
        echo "" >> "book/$PART/_toc.md"
        echo "Done. Now run 'ebg build book' to build the book."
        ;;
      *)
        usage
        ;;
      esac
    ;;
  build)
    case "$2" in
      book)
        extension=${3:-pdf}
        echo "Building book... as $extension"
        build_book "$extension"
        ;;
      expose)
        echo "Building expose..."
        build_expose
        ;;
      *)
        usage
        ;;
      esac
    ;;
  *)
    usage
    ;;
esac

