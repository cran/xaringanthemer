read_css_vars <- function(file = NULL) {
  if (is.null(file)) {
    css_candidates <- find_xaringan_themer_css()
    file <- choose_xaringan_themer_css(css_candidates)
  }

  css_get_root(file)
}

find_xaringan_themer_css <- function() {
  # finds xaringan themer files within or below current working directory
  # and is only ever intended to be called in that situation
  css_files <- list.files(pattern = "css$", recursive = TRUE, full.names = TRUE)
  css_files_head <- purrr::map(css_files, readLines, n = 5)
  is_xt <- grepl(pattern = "generated by xaringanthemer", css_files_head, fixed = TRUE)

  css_files[is_xt]
}

choose_xaringan_themer_css <- function(css_candidates = character(0)) {
  if (!length(css_candidates)) {
    stop("Unable to locate a xaringanthemer css file.", call. = FALSE)
  } else if (length(css_candidates) == 1) {
    file <- css_candidates
  } else if (length(css_candidates) > 1) {
    is_xaringan_themer_css <- grepl("xaringan-themer.css", css_candidates, fixed = TRUE)
    if (any(is_xaringan_themer_css)) {
      file <- css_candidates[is_xaringan_themer_css][1]
    } else {
      file <- css_candidates[1]
      message(glue::glue("Using xaringanthemer theme in {file}"))
    }
  }
  file
}

css_get_root <- function(file) {
  x <- readLines(file, warn = FALSE)
  x <- paste(x, collapse = "\n")
  where <- regexpr(":root\\s*\\{[^}]+\\}", x)
  if (where < 0) return(NULL)
  x <- substr(x, where, where + attr(where, "match.length"))
  x <- strsplit(x, "\n")[[1]]
  m <- regexec("--(.+):\\s*(.+?);", x)
  x <- regmatches(x, m)
  x <- purrr::compact(x)
  vars <- gsub("-", "_", purrr::map_chr(x, `[`, 2))
  values <- purrr::map(x, `[`, 3)
  names(values) <- vars
  for (font_type in c("text", "header", "code")) {
    font_is_google <- paste0(font_type, "_font_is_google")
    values[[font_is_google]] <- if (!is.null(values[[font_is_google]])) {
      values[[font_is_google]] %in% c("1", "TRUE", "true", "yes")
    } else FALSE
  }
  values
}

css_get_padding <- function(x) {
  stopifnot(length(x) == 1)
  x <- trimws(x)
  x <- as.list(strsplit(x, " ")[[1]])
  stopifnot(length(x) %in% c(1, 2, 4))
  names(x) <- c("top", "right", "bottom", "left")[seq_along(x)]
  list(
    top = x$top,
    right = x$right %||% x$top,
    bottom = x$bottom %||% x$top,
    left = x$left %||% x$right %||% x$top
  )
}
