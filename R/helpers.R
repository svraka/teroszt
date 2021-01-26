#' Get a postal code to settlement ID crosswalk
#'
#' Aggregate a settlement ID to postal code crosswalk table by the unique
#' primary settlement (\code{torzsszam_fo_telepules}) to get an unambiguous
#' postal code to settlement ID crosswalk.
#'
#' @param year Version of the crosswalk table to be used. Defaults to
#'   2018.
#'
#' @details Note that currently this package includes just a single crosswalk
#'   table, \code{\link{irsz_2018}}.
#'
#' @return A tibble
#' @export
get_irsz_tsz_crosswalk <- function(year = c("2018")) {
  year <- match.arg(year)
  switch(year,
         "2018" = irsz_tsz_crosswalk_aggreage(irsz_2018))
}

#' Helper function for \code{\link{get_irsz_tsz_crosswalk}}
#'
#' @param df A settlement ID to postal code crosswalk table to aggregate.
#'
#' @keywords internal
irsz_tsz_crosswalk_aggreage <- function(df) {
  df <- df[, c("irsz", "torzsszam_fo_telepules")]
  names(df)[2] <- "torzsszam"

  res <- stats::aggregate(df, by = list(df$irsz),
                          FUN = function(x) utils::head(x, 1))
  res$Group.1 <- NULL
  res <- tibble::as_tibble(res)

  res
}
