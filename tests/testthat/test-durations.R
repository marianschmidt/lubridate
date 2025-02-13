test_that("duration() returns zero-length vector", {
  x <- duration()
  expect_s4_class(x, "Duration")
  expect_length(x, 0)
  expect_equal(format(x), character())
  expect_output(print(x), "<Duration[0]>", fixed = TRUE)
})

test_that("duration(...) returns zero-length with on 0-length inputs", {
  x <- duration(character())
  expect_s4_class(x, "Duration")
  expect_length(x, 0)

  x <- duration(hour = numeric())
  expect_s4_class(x, "Duration")
  expect_length(x, 0)

  x <- duration(numeric(), hour = numeric())
  expect_s4_class(x, "Duration")
  expect_length(x, 0)

  expect_equal(
    duration(c(30, 20)),
    duration(c(30, 20), days = numeric())
  )

  expect_equal(
    duration(numeric(), days = 10),
    duration(days = 10)
  )
})

test_that("duration constructor doesn't accept non-numeric or non-character inputs", {
  expect_error(duration(interval(ymd("2014-01-01"), ymd("2015-01-01"))))
})

test_that("make_difftime works as expected", {
  x <- as.POSIXct("2008-08-03 13:01:59", tz = "UTC")
  y <- difftime(x + 5 + 30 * 60 + 60 * 60 + 14 * 24 * 60 * 60, x, tz = "UTC")
  attr(y, "tzone") <- NULL
  diff <- make_difftime(seconds = 5, minutes = 30, days = 0, hour = 1, weeks = 2)
  expect_equal(diff, y)
})

test_that("Duration parsing works", {
  expect_equal(
    duration("1min 2sec 2secs 1H 2M 1d"),
    duration(seconds = 4, minutes = 3, hours = 1, days = 1)
  )
  expect_equal(
    duration("day day"),
    duration(days = 2)
  )
  expect_equal(
    duration("S M H d w"),
    duration(seconds = 1, minutes = 1, hours = 1, days = 1, weeks = 1)
  )
  expect_equal(
    duration("1S 2M 3H 4d 5w"),
    duration(seconds = 1, minutes = 2, hours = 3, days = 4, weeks = 5)
  )
})

test_that("fractional parsing works as expected", {
  expect_equal(
    duration("1.1min 2.3sec 2.3secs 1.0H 2.2M 1.5d"),
    duration(seconds = 43222.6, minutes = 3, hours = 1, days = 1)
  )
  expect_equal(
    duration("day 1.2days"),
    duration(days = 2, seconds = 17280)
  )
})

test_that("sub-unit fractional parsing works as expected", {
  expect_identical(
    duration(".1min .3sec .3secs .0H .2M .5d"),
    duration("0.1min 0.3sec 0.3secs 0.0H 0.2M 0.5d")
  )

  expect_identical(
    duration(".1min .3sec .3secs .0H .2M .5d"),
    duration(seconds = 6.6, minutes = .2, hours = 12)
  )
})

test_that("parsing with 0 units works as expected", {
  expect_equal(as.numeric(duration("2d 0H 0M 1s")), 2 * 24 * 3600 + 1)
  expect_equal(as.numeric(duration("0d 0H 0M 1s")), 1)
  expect_equal(period("2d 0H 0M 1s"), days(2) + seconds(1))
  expect_equal(period("y 0m 2d 0H 0M 1s"), years(1) + days(2) + seconds(1))
})

test_that("make_difftime handles vectors", {
  x <- as.POSIXct(c("2008-08-03 13:01:59", "2008-08-03 13:01:59"), tz = "UTC")
  y <- difftime(x + c(
    5 + 30 * 60 + 60 * 60 + 14 * 24 * 60 * 60,
    1 + 3 * 24 * 60 * 60 + 60 * 60
  ), x, tz = "UTC")
  attr(y, "tzone") <- NULL
  z <- difftime(x + c(
    5 + 30 * 60 + 60 * 60 + 14 * 24 * 60 * 60,
    5 + 30 * 60 + 60 * 60 + 14 * 24 * 60 * 60 + 3 * 24 * 60 * 60
  ),
  x,
  tz = "UTC"
  )
  attr(z, "tzone") <- NULL

  expect_equal(
    make_difftime(
      seconds = c(5, 1), minutes = c(30, 0),
      days = c(0, 3), hour = c(1, 1), weeks = c(2, 0)
    ),
    y
  )

  expect_equal(
    make_difftime(
      seconds = 5, minutes = 30,
      days = c(0, 3), hour = 1, weeks = 2
    ),
    z
  )
})

test_that("duration works as expected", {
  dur <- duration(
    seconds = 5, minutes = 30, days = 0,
    hour = 1, weeks = 2
  )

  expect_equal(dur@.Data, 1215005)
  expect_s4_class(dur, "Duration")
})

test_that("duration handles vectors", {
  dur1 <- duration(
    seconds = c(5, 1), minutes = c(30, 0),
    days = c(0, 3), hour = c(1, 1), weeks = c(2, 0)
  )
  dur2 <- duration(
    seconds = 5, minutes = 30, days =
      c(0, 3), hour = 1, weeks = 2
  )

  expect_equal(dur1@.Data, c(1215005, 262801))
  expect_equal(dur2@.Data, c(1215005, 1474205))
  expect_s4_class(dur1, "Duration")
  expect_s4_class(dur2, "Duration")
})

test_that("as.duration handles vectors", {
  expect_equal(as.duration(minutes(1:3)), dminutes(1:3))
})

test_that("as.duration handles periods", {
  expect_equal(as.duration(seconds(1)), dseconds(1))
  expect_equal(as.duration(minutes(2)), dminutes(2))
  expect_equal(as.duration(hours(3)), dhours(3))
  expect_equal(as.duration(days(4)), ddays(4))
  expect_equal(as.duration(weeks(5)), dweeks(5))
  expect_equal(as.duration(months(1)), dseconds(60 * 60 * 24 * 365.25 / 12))
  expect_equal(as.duration(years(1)), dseconds(60 * 60 * 24 * 365.25))
  expect_equal(as.duration(seconds(1) + minutes(4)), dseconds(1) + dminutes(4))
})

test_that("parsing duration's allows for a full roundtrip", {
  expect_equal(as.duration(lubridate:::parse_period("31557600s (~1 years)")), dseconds(31557600))
  durs <- duration(c("1m 2s, 3days", "2.5min 1day"))
  expect_equal(durs, as.duration(as.character(durs)))
})

test_that("as.duration handles intervals", {
  time1 <- as.POSIXct("2009-01-02 12:24:03", tz = "UTC")
  time2 <- as.POSIXct("2010-02-03 14:31:42", tz = "UTC")
  dur <- as.duration(interval(time1, time2))
  y <- as.numeric(time2 - time1, units = "secs")

  expect_equal(dur@.Data, y)
  expect_s4_class(dur, "Duration")
})

test_that("as.duration handles difftimes", {
  x <- difftime(
    as.POSIXct("2010-02-03 14:31:42", tz = "UTC"),
    as.POSIXct("2009-01-02 12:24:03", tz = "UTC")
  )
  dur <- as.duration(x)
  y <- as.numeric(x, units = "secs")

  expect_equal(dur@.Data, y)
  expect_s4_class(dur, "Duration")
})

test_that("eobjects handle vectors", {
  dur <- dseconds(c(1, 3, 4))

  expect_equal(dur@.Data, c(1, 3, 4))
  expect_s4_class(dur, "Duration")
})

test_that("is.duration works as expected", {
  ct_time <- as.POSIXct("2008-08-03 13:01:59", tz = "UTC")
  lt_time <- as.POSIXlt("2009-08-03 13:01:59", tz = "UTC")

  expect_false(is.duration(234))
  expect_false(is.duration(ct_time))
  expect_false(is.duration(lt_time))
  expect_false(is.duration(Sys.Date()))
  expect_false(is.duration(minutes(1)))
  expect_true(is.duration(dminutes(1)))
  expect_false(is.duration(make_difftime(1000)))
  expect_false(is.duration(interval(lt_time, ct_time)))
})

test_that("format.Duration works as expected", {
  dur <- duration(seconds = c(5, NA, 10, -10, 1000, -1000))
  expect_equal(
    format(dur),
    c(
      "5s", NA, "10s", "-10s",
      "1000s (~16.67 minutes)",
      "-1000s (~-16.67 minutes)"
    )
  )
})

test_that("summary.Duration creates useful summary", {
  dur <- dminutes(5)
  text <- c(rep("300s (~5 minutes)", 6), 1)
  names(text) <- c("Min.", "1st Qu.", "Median", "Mean", "3rd Qu.", "Max.", "NA's")
  expect_equal(summary(c(dur, NA)), text)
})

test_that("format.Duration works with NA values", {
  expect_equal(
    format(duration(c(NA, 1, 100, 10000, 100000, 100000000, 75.25, 75.5001)), scientific = 7),
    c(
      NA, "1s", "100s (~1.67 minutes)", "10000s (~2.78 hours)", "1e+05s (~1.16 days)",
      "1e+08s (~3.17 years)",
      "75.25s (~1.25 minutes)", "75.5001s (~1.26 minutes)"
    )
  )
  expect_equal(
    format(duration(c(75.25, 75.5001))),
    c("75.25s (~1.25 minutes)", "75.5001s (~1.26 minutes)")
  )
})

test_that("as.duration handles NA interval objects", {
  one_missing_date <- as.POSIXct(NA_real_, origin = origin)
  one_missing_interval <- interval(
    one_missing_date,
    one_missing_date
  )
  several_missing_dates <- rep(as.POSIXct(NA_real_, origin = origin), 2)
  several_missing_intervals <- interval(
    several_missing_dates,
    several_missing_dates
  )
  start_missing_intervals <- interval(several_missing_dates, origin)
  end_missing_intervals <- interval(origin, several_missing_dates)
  na.dur <- dseconds(NA)

  expect_equal(as.duration(one_missing_interval), na.dur)
  expect_equal(as.duration(several_missing_intervals), c(na.dur, na.dur))
  expect_equal(as.duration(start_missing_intervals), c(na.dur, na.dur))
  expect_equal(as.duration(end_missing_intervals), c(na.dur, na.dur))
})

test_that("as.duration handles NA period objects", {
  na.dur <- dseconds(NA)
  expect_equal(as.duration(years(NA)), na.dur)
  expect_equal(as.duration(years(c(NA, NA))), c(na.dur, na.dur))
  expect_equal(as.duration(years(c(1, NA))), c(dyears(1), na.dur))
})

test_that("as.duration handles NA objects", {
  na.dur <- dseconds(NA)
  expect_equal(as.duration(NA), na.dur)
})
