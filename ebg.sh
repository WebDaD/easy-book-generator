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
  echo '# Expose' >> "$filename"
  echo '' >> "$filename"
  echo '## Overview' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/overview.md' >> "$filename"
  echo '' >> "$filename"
  echo '\newpage' >> "$filename"
  echo '' >> "$filename"
  echo '## Key Features' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/key_features.md' >> "$filename"
  echo '' >> "$filename"
  echo '\newpage' >> "$filename"
  echo '' >> "$filename"
  echo '## Target Audience' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/target_audience.md' >> "$filename"
  echo '' >> "$filename"
  echo '\newpage' >> "$filename"
  echo '' >> "$filename"
  echo '## Selling Points' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/selling_points.md' >> "$filename"
  echo '' >> "$filename"
  echo '\newpage' >> "$filename"
  echo '' >> "$filename"
  echo '## Similar Books' >> "$filename"
  echo '' >> "$filename"
  echo '!include expose/similar_books.md' >> "$filename"
  echo '' >> "$filename"
  echo '\newpage' >> "$filename"
  echo '' >> "$filename"
  echo '## About the Author' >> "$filename"
  echo '' >> "$filename"
  echo '!include book/about_the_author.md' >> "$filename"
  echo '' >> "$filename"
  echo '\newpage' >> "$filename"
  echo '' >> "$filename"
  echo '## Text Sample' >> "$filename"
  echo '' >> "$filename"
  echo 'TODO: add a text sample' >> "$filename"
  echo '' >> "$filename"
}
build_expose() {
  expose_tmp="${TEMP_DIR}/expose.md"
  # combine all the markdown files into one
  perl -ne 's/^\!include\s(.+)$/`cat $1`/e;print' expose/_expose.md > "$expose_tmp"

  # remove all tags from the markdown
  #perl -pi -e 's/---//g' "$expose_tmp"
  #perl -pi -e 's/^tag(.+)$//g' "$expose_tmp"

  # combine triple new lines into one
  perl -pi -e 's/\n\n\n/\n\n/g' "$expose_tmp"


  # convert to pdf
  pandoc metadata.yaml "$expose_tmp"  -o "export/expose.pdf"

  # try to open file in preview
  open "export/expose.pdf"
}
build_book() {
  extension=$1
  book_tmp="${TEMP_DIR}/book.md"
  # combine all the markdown files into one
  perl -ne 's/^\!include\s(.+)$/`cat $1`/e;print' book/_toc.md > "$book_tmp"_1

  perl -ne 's/^\!include\s(.+)$/`cat $1`/e;print' "$book_tmp"_1 > "$book_tmp"

  # remove all tags from the markdown
  perl -pi -e 's/---//g' "$book_tmp"
  perl -pi -e 's/^tag(.+)$//g' "$book_tmp"

  # combine triple new lines into one
  perl -pi -e 's/\n\n\n/\n\n/g' "$book_tmp"

  # convert to pdf
  pandoc "$book_tmp" --metadata-file=metadata.yaml --toc -o "export/book.$extension"

  # try to open file in preview
  open "export/book.$extension"
}

analyse_book_status() {
  # Load every markdown-file under the book directory
  # check for todos and print all of them
  # also count the todos and print the number
  # check every file for the tag "draft" and print all of them
  # also count the drafts and print the number
  # check every file for the tag "todo" and print all of them
  # also count the todos and print the number
  # check every file for the tag "done" and print all of them
  # also count the dones and print the number
  # calculate the percentage of done tags to other tags
  # print the percentage
  book_dir="book"
  
  # Initialize counters
  todo_count=0
  draft_count=0
  done_count=0
  
  # Loop through markdown files in the book directory and subdirectories
  while IFS= read -r -d '' file; do
    # Extract tag from yaml part
    tag=$(awk '/^tag:/ {print $2}' "$file")
    
    case "$tag" in
      todo)
        echo "TODO: $file"
        ((todo_count++))
        ;;
      draft)
        echo "Draft: $file"
        ((draft_count++))
        ;;
      done)
        echo "Done: $file"
        ((done_count++))
        ;;
    esac
    
    # Check for TODO string in file
    if grep -q "TODO" "$file"; then
      echo "TODO found in $file"
    fi
    
  done < <(find "$book_dir" -type f -name "*.md" -print0)
  
  total_files=$((todo_count + draft_count + done_count))
  
  echo "-------------------"
  echo "Total TODOs: $todo_count"
  echo "Total Drafts: $draft_count"
  echo "Total Dones: $done_count"
  echo "-------------------"
  
  # Calculate and print percentages
  if ((total_files > 0)); then
    done_percentage=$((done_count * 100 / total_files))
    echo "Percentage Done: $done_percentage%"
  else
    echo "No files found."
  fi



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
  echo "  status       - check the status of the book (TODOs, drafts, etc)"
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
    echo '---' > book/_toc.md
    echo 'tag: todo' >> book/_toc.md
    echo '---' >> book/_toc.md
    echo '' >> book/_toc.md
    echo "" >> book/_toc.md
    echo "# $TITLE" >> book/_toc.md
    echo "" >> "book/_toc.md"

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
    echo "---" > metadata.yaml
    echo "title: $TITLE" >> metadata.yaml
    echo "subtitle: TODO" >> metadata.yaml
    echo "title_slug: $TITLE_SLUG" >> metadata.yaml
    echo "author: TODO" >> metadata.yaml
    echo "date: TODO" >> metadata.yaml
    echo "lang: TODO" >> metadata.yaml
    echo "toc: true" >> metadata.yaml
    echo "toc-depth: 2" >> metadata.yaml
    echo "toc-title: Inhaltsverzeichnis" >> metadata.yaml
    echo "numbersections: true" >> metadata.yaml
    echo "include-before:" >> metadata.yaml
    echo "- '\`\newpage{}\`{=latex}'" >> metadata.yaml
    echo "---" >> metadata.yaml

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
        echo "## $PART_TITLE" >> "book/_toc.md"
        echo "" >> "book/_toc.md"
        echo "!include book/$PART_TITLE_SLUG/_toc.md" >> book/_toc.md
        echo "" >> "book/_toc.md"
        echo "\newpage" >> "book/_toc.md"
        echo "" >> "book/_toc.md"
        echo "Done. Now run 'ebg add chapter' to add a chapter to the part."
        ;;
      chapter)
        # must be in a part folder or part is specified via slug
        if [ -d "$(pwd)/book/$3" ]; then
          PART="$3"
        elif [[ "$(basename "$(dirname "$(pwd)")")" == "book" && -f "_toc.md" ]]; then
          PART="$(basename "$(pwd)")"
        else
          echo "Error: You are not in a part folder under the 'book' directory. Please change to a part folder or specify the part slug as the third argument."
          exit 1
        fi
        CHAPTER_TITLE=$(get_string "$4" "chapter title")
        CHAPTER_TITLE_SLUG=$(slugify "$CHAPTER_TITLE")
        echo "Adding new chapter with title $CHAPTER_TITLE to part $PART..."
        MYPATH="$(pwd)/book"
        # perform add logic
        touch "$MYPATH/$PART/$CHAPTER_TITLE_SLUG.md"
        echo '---' > "$MYPATH/$PART/$CHAPTER_TITLE_SLUG.md"
        echo 'tag: todo' >> "$MYPATH/$PART/$CHAPTER_TITLE_SLUG.md"
        echo '---' >> "$MYPATH/$PART/$CHAPTER_TITLE_SLUG.md"
        echo '' >> "$MYPATH/$PART/$CHAPTER_TITLE_SLUG.md"
        echo "" >> "$MYPATH/$PART/_toc.md"
        echo "### $CHAPTER_TITLE" >> "$MYPATH/$PART/_toc.md"
        echo "" >> "$MYPATH/$PART/_toc.md"
        echo "!include book/$PART/$CHAPTER_TITLE_SLUG.md" >> "$MYPATH/$PART/_toc.md"
        echo "" >> "$MYPATH/$PART/_toc.md"
        echo "\newpage" >> "$MYPATH/$PART/_toc.md"
        echo "" >> "$MYPATH/$PART/_toc.md"
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
  status)
    echo "Analysing book..."
    analyse_book_status
    ;;
  *)
    usage
    ;;
esac

