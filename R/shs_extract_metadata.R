#' Extract survey metadata from Excel
#'
#' \code{shs_extract_metadata} extracts survey metadata from Excel workbooks in a specified location,
#' and saves all sheets as .Rds files in a newly created location.
#' Internal function for \code{shs_extract_data}.
#'
#' @return \code{null}.
#'
#' @examples
#' shs_extract_metadata()
#'
#' @keywords internal
#'
#' @noRd

shs_extract_metadata <- function(source_metadata_path,
                                 extracted_metadata_path) {

  # Get all metadata files
  files <- list.files(source_metadata_path)

  # Loop through metadata files
  for (file in files) {

    # Get sheets in file
    workbook_path <- file.path(source_metadata_path, file)
    workbook <- XLConnect::loadWorkbook(workbook_path)
    sheets <- readxl::excel_sheets(workbook_path)

    # Save sheet as .Rds file in output directory
    for (sheet in sheets) {
      df <- XLConnect::readWorksheet(workbook, sheet = sheet, header = TRUE)
      saveRDS(df, file = file.path(extracted_metadata_path,
                                   paste0(sheet, ".Rds")))
    }
  }
}