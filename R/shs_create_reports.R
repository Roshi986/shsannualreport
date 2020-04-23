#' Create Rmd reports for each chapter
#'
#' \code{shs_create_reports} creates an Rmd report file for each topic in the SHS annual report data.
#'
#' @return \code{null}.
#'
#' @examples
#' \dontrun{
#' shs_create_reports()
#' }
#'
#' @export

shs_create_reports <- function() {

  topics <- readRDS("app/data/metadata/topic_titles.Rds")
  topics <- topics[topics$has_data == "y",]

  questions <- readRDS("app/data/metadata/question_titles.Rds")

  for (row in 1:nrow(topics)) {

    topic_id <- topics[row, "code"]
    title <- topics[row, "title"]
    report_file_path <- paste0("app/reports/", topic_id, ".Rmd")

    number <- sub("Top", "", topic_id)
    topic_questions <- questions[questions$Topic == number,]

    file.create(report_file_path)

    cat(
      "---
title: \"Scotland's People Local Authority Tables\"
output:
  pdf_document:
    toc: yes
    latex_engine: xelatex
    fig_caption: false
mainfont: Calibri
classoption: landscape
fontsize: 10pt
papersize: a4
geometry: margin=1.5cm
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo=FALSE)
options(tinytex.verbose = TRUE)

library(knitr)
library(dplyr)
library(kableExtra)
library(png)

local_authority <- params$local_authority
year <- params$year
topic_data <- params$topic_data
comparison_type <- params$comparison_type
comparator <- params$comparator

",
      file = report_file_path, append = TRUE)

    counter <- 1

    for (row in 1:nrow(topic_questions)) {

      question_id <- topic_questions[row, "ID"]
      question_id_underscore <- gsub(",", "", question_id)
      question_id_underscore <- gsub(" ", "_", question_id_underscore)

      string <- paste0(question_id_underscore, " <- topic_data[[", counter, "]]
")

      cat(string, file = report_file_path, append = TRUE)

      counter <- counter + 1

    }

    cat(
      "
main_table_title <- paste0(local_authority, \", \", year)

eval_comparison <- ifelse(comparison_type == \"No comparison\", FALSE, TRUE)

eval_comparison_time_series <- ifelse(comparison_type == \"Year\" | comparison_type == \"No comparison\", FALSE, TRUE)

comparison_table_title <- if (comparison_type == \"Local Authority\") {
  paste0(comparator, \", \", year)
} else if (comparison_type == \"Year\") {
  paste0(local_authority, \", \", comparator)
} else {
  NULL
  }

```
```{r, out.height = \"130pt\", fig.show='hold', fig.align='center'}
knitr::include_graphics(c(\"../www/shs-logo.png\", \"../www/home_logo.png\"))
```

## Acknowledgements
The Scottish Government acknowledges and thanks the 10,530
people across Scotland who gave their time to take part in the
Scottish Household Survey 2018.
This report was produced by the Scottish Household Survey Project Team
at the Scottish Government.
We would also like to thank all the Scottish Government lead analysts who
contributed to the project.
Finally, special thanks to Ipsos MORI and their interviewers for continuous
and relentless efforts during the fieldwork.

", file = report_file_path, append = TRUE)

    counter_2 <- 1

    for (row in 1:nrow(topic_questions)) {

      question_id <- topic_questions[row, "ID"]
      question_id_underscore <- gsub(",", "", question_id)
      question_id_underscore <- gsub(" ", "_", question_id_underscore)
      title <- topic_questions[row, "Title"]
      type <- topic_questions[row, "Type"]
      coverage <- topic_questions[row, "Coverage"]
      comment <- topic_questions[row, "Comment"]
      link <- topic_questions[row, "Link"]

      if (type != "0") {

        data_file_path <- paste0("app/data/dataset/", question_id, ".Rds")

        print(data_file_path)

        column_names <- colnames(readRDS(data_file_path))
        significance_column_names <- gsub("_l", "", column_names[grep("_l", column_names)])
        significance_column_names <- significance_column_names[!significance_column_names %in% c("All", "Base")]

        if (type == 1) {

          markdown_comparator <- "eval_comparison_time_series"

        } else {

          markdown_comparator <- "eval_comparison"
        }

      }

      string <- paste0("## ", question_id, ": ", title, "\n")

      if (type == 0) {

        string <- paste0(string, "### Base numbers at local authority level are too small to produce robust analysis.\n")

      } else if (type %in% c(1, 2)) {

        string <- paste0(string, "### Column percentages, ", coverage, "\n")

      } else if (type == 3) {

        string <- paste0(string, "### Row percentages, ", coverage, "\n")

      } else if (type == 4) {

        string <- paste0(string, "### Grossed-up estimates (Rounded to the nearest 10,000)\n")
      }

      if (!is.na(comment)) {

        string <- paste0(string, "### ", comment, "\n")
      }

      if (!is.na(link)) {

        link_comment_pattern = ">(.*?)<"
        link_comment <- regmatches(link, regexec(link_comment_pattern, link))[[1]][2]

        url_pattern = "<a href=\"(.*?)\">"
        url <- regmatches(link, regexec(url_pattern, link))[[1]][2]

        string <- paste0(string, "### [", link_comment, "]", "(", url, ")\n")
      }

      if (type == 4) {
        string <- paste0(string, "\n",
                         "```{r}\n",
                         "kable(", question_id_underscore, ")\n",
                         "```\n")
      }

      if (type %in% c(1, 2, 3)) {
        string <- paste0(string, "
### `r main_table_title`

```{r eval=(", markdown_comparator, " == FALSE)}\n",
                         question_id_underscore, " %>%
kable(\"latex\")
```

```{r eval=", markdown_comparator, "}
main_column_names <- colnames(", question_id_underscore, ")[!grepl(\"_2\", colnames(", question_id_underscore, "))]
significance_column_names <- colnames(", question_id_underscore, ")[grepl(\"_sig\", colnames(", question_id_underscore, "))]

", question_id_underscore, " %>% select(all_of(main_column_names)) %>%
mutate(")

        for (significance_column_name in significance_column_names) {

          append_string <- paste0("`", significance_column_name, "` = cell_spec(`", significance_column_name,
                                  "`, \"latex\", background = case_when(`", significance_column_name,
                                  "_sig` == \"HIGHER\" ~ \"#00A3A3\", `", significance_column_name, "_sig` == \"LOWER\" ~ \"#C3C3FF\", TRUE ~ \"white\")),\n")

          string <- paste0(string, append_string)

        }

        string <- paste0((substr(string, 1, nchar(string ) - 2)),
                         "\n", "
) %>%
select(!all_of(significance_column_names)) %>%
kable(\"latex\", escape = FALSE)
```

```{r eval=", markdown_comparator, "}
asis_output(paste0(\"### \", comparison_table_title))
```

```{r eval=", markdown_comparator, "}
comparison_column_names <- colnames(", question_id_underscore, ")[grepl(\"_2\", colnames(", question_id_underscore, "))]
comparison_rename_column_names <- gsub(\"_2\", \"\", comparison_column_names)

", question_id_underscore, " %>% select(all_of(colnames(", question_id_underscore, ")[!colnames(", question_id_underscore, ") %in% comparison_rename_column_names])) %>%
rename_at(comparison_column_names, ~ comparison_rename_column_names) %>%
mutate("
        )

        for (significance_column_name in significance_column_names) {

          append_string <- paste0("`", significance_column_name, "` = cell_spec(`", significance_column_name, "`, \"latex\", background = case_when(`", significance_column_name, "_sig` == \"HIGHER\" ~ \"#C3C3FF\", `", significance_column_name, "_sig` == \"LOWER\" ~ \"#00A3A3\", TRUE ~ \"white\")),\n")

          string <- paste0(string, append_string)

        }

        string <- paste0(substr(string, 1, nchar(string ) - 2),
                         ") %>%
        select(!all_of(significance_column_names)) %>%
        kable(\"latex\", escape = FALSE)
```\n")
      }

      cat(string, file = report_file_path, append = TRUE)

      counter_2 <- counter_2 + 1

    }
  }

}
