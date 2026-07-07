test_that("package is at expected development version", {
  expect_equal(as.character(utils::packageVersion("revpiper")), "0.0.0.9000")
})
