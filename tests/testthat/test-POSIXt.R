test_that("is.POSIXt works as expected", {
  expect_false(is.POSIXt(234))
  expect_true(is.POSIXt(as.POSIXct("2008-08-03 13:01:59", tz = "UTC")))
  expect_true(is.POSIXt(as.POSIXlt("2008-08-03 13:01:59", tz = "UTC")))
  expect_false(is.POSIXt(Sys.Date()))
  expect_false(is.POSIXt(minutes(1)))
  expect_false(is.POSIXt(dminutes(1)))
  expect_false(is.POSIXt(interval(
    as.POSIXct("2008-08-03 13:01:59", tz = "UTC"),
    as.POSIXct("2009-08-03 13:01:59", tz = "UTC")
  )))
})

test_that("is.POSIXt handles vectors", {
  expect_true(is.POSIXt(c(
    as.POSIXct("2008-08-03 13:01:59", tz = "UTC"),
    as.POSIXct("2009-08-03 13:01:59", tz = "UTC")
  )))
})

test_that("c.POSIXct deals correctly with heterogeneous date-time classes", {
  d <- make_date(2000, 1, 1)
  dt <- make_datetime(2000, 1, 1, tz = "Europe/Berlin")
  expect_equal(c(dt, d), make_datetime(c(2000, 2000), 1, 1, tz = "Europe/Berlin"))
  expect_equal(c(dt, list(d)), make_datetime(c(2000, 2000), 1, 1, tz = "Europe/Berlin"))
  expect_equal(c(dt, list(d, list(d))), make_datetime(c(2000, 2000, 2000), 1, 1, tz = "Europe/Berlin"))
  dt <- make_datetime(2000, 1, 1, tz = "UTC")
  expect_equal(c(dt, d), make_datetime(c(2000, 2000), 1, 1, tz = "UTC"))


  ct <- as.POSIXct("1999-01-01 01:02:03", tz = "America/New_York")
  lt <- as.POSIXlt("2001-01-30 01:02:03", tz = "Europe/Berlin")
  expect_equal(c(ct, lt), ymd_hms(c("1999-01-01 01:02:03", "2001-01-29 19:02:03"), tz = "America/New_York"))
  expect_equal(c(lt, ct), as.POSIXlt(ymd_hms(c("2001-01-30 01:02:03", "1999-01-01 07:02:03"), tz = "Europe/Berlin")))
})


test_that("c.POSIXct deals correctly with empty vectors", {
  expect_equal(c(POSIXct()), POSIXct())
  expect_equal(c(POSIXct(), POSIXct()), POSIXct())
  expect_equal(c(POSIXct(), Date()), POSIXct())
  expect_equal(c(POSIXct(tz = "America/New_York")), POSIXct(tz = "America/New_York"))
  expect_equal(
    c(ymd("2021-01-01", tz = "America/New_York"), NULL, c()),
    ymd("2021-01-01", tz = "America/New_York")
  )
  expect_equal(
    c(
      ymd("2021-01-01", tz = "America/New_York"), POSIXct(),
      ymd("2021-01-02", tz = "America/New_York")
    ),
    ymd(c("2021-01-01", "2021-01-02"), tz = "America/New_York")
  )
  expect_equal(
    c(ymd("2021-01-01", tz = "UTC"), POSIXct(), ymd("2021-01-02"), NULL),
    ymd(c("2021-01-01", "2021-01-02"), tz = "UTC")
  )
})

# as_datetime -------------------------------------------------------------

test_that("converts numeric", {
  dt <- as_datetime(0)
  expect_s3_class(dt, "POSIXct")
  expect_equal(tz(dt), "UTC")
  expect_equal(unclass(dt)[[1]], 0)
})

test_that("converts date", {
  dt <- as_datetime(as.Date("1970-01-01"))
  expect_s3_class(dt, "POSIXct")
  expect_equal(tz(dt), "UTC")
  expect_equal(unclass(dt)[[1]], 0)
})

test_that("as_datetime.Date respects tz and sets HMS to 00:00:00", {
  d <- ymd(c("2000-01-01", "2020-10-10"))
  expect_equal(
    as_datetime(d, tz = "Europe/Berlin"),
    ymd(c("2000-01-01", "2020-10-10"), tz = "Europe/Berlin")
  )
  expect_equal(
    as_datetime(d),
    ymd(c("2000-01-01", "2020-10-10"), tz = "UTC")
  )
})

test_that("converts character", {
  chars <- c("2017-03-22T15:48:00.000Z", "2017-03-01 0:0:0", "2017-03-01 0:0:0.23", "2017-03-01 0:0:0.23")
  dt <- as_datetime(chars)
  expect_s3_class(dt, "POSIXct")
  expect_equal(tz(dt), "UTC")
  expect_equal(dt, ymd_hms(chars))
  expect_equal(suppressMessages(as_datetime(chars, tz = "Europe/Amsterdam")), ymd_hms(chars, tz = "Europe/Amsterdam", quiet = TRUE))
})

test_that("changes timezone of POSIXct", {
  dt <- as_datetime(make_datetime(tz = "America/Chicago"))
  expect_equal(tz(dt), "UTC")
})

test_that("addition of large seconds doesn't overflow", {
  from_period <- origin + seconds(2^31 + c(-2:2))
  from_char <- ymd_hms(c(
    "2038-01-19 03:14:06", "2038-01-19 03:14:07", "2038-01-19 03:14:08",
    "2038-01-19 03:14:09", "2038-01-19 03:14:10"
  ))
  expect_equal(from_period, from_char)
})

test_that("as_datetime works correctly", {
  x <- c(
    "17-01-20", "2017-01-20 01:02:03", "2017-03-22T15:48:00.000Z",
    "2017-01-20", "2017-01-20 01:02:03", "2017-03-22T15:48:00.000Z"
  )

  y <- c(
    "2017-01-20 00:00:00 UTC", "2017-01-20 01:02:03 UTC",
    "2017-03-22 15:48:00 UTC", "2017-01-20 00:00:00 UTC",
    "2017-01-20 01:02:03 UTC", "2017-03-22 15:48:00 UTC"
  )

  zns <- c(3, 6)
  putc <- ymd_hms(y)
  pus <- ymd_hms(y[-zns], tz = "America/Chicago")
  expect_equal(as_datetime(x), putc)
  expect_equal(as_datetime(x[-zns], tz = "America/Chicago"), pus)

  for (i in seq_along(x)) {
    expect_equal(as_datetime(x[[i]]), putc[[i]])
  }

  for (i in seq_along(pus)) {
    expect_equal(as_datetime(x[-zns][[i]], tz = "America/Chicago"), pus[[i]])
  }
})

test_that("as_datetime() always returns POSIXct", {
  expect_s3_class(as_datetime("2010-01-01"), "POSIXct")
  expect_s3_class(as_datetime("2010-01-01", format = "%Y-%m-%d"), "POSIXct")
})
