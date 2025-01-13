# Code for generating age-specific partnership durations from ARTnet data
# lifted from `build_netparams`

# Create output list
out <- list()

## Durations (MAIN) ----
## Inputs ##
geog.lvl <- epistats$geog.lvl
race <- epistats$race
age.limits = epistats$age.limits
age.breaks = epistats$age.breaks
age.sexual.cessation = epistats$age.sexual.cessation
sex.cess.mod <- epistats$sex.cess.mod
age.grps = epistats$age.grps
time.unit <- epistats$time.unit
smooth.main.dur = FALSE

# Fix global binding check error
duration.time <- NULL

# 0. Data Processing ------------------------------------------------------

## Age Processing ##

## Data ##
d <- ARTnetData::ARTnet.wide
l <- ARTnetData::ARTnet.long


# p_age_imp initialization for lintr
p_age_imp <- NULL

# Subset datasets by lower age limit and age.sexual.cessation
# Now applies to both index (respondents) and partners for long dataset
l <- subset(l, age >= age.limits[1] & age < age.sexual.cessation &
              p_age_imp >= age.limits[1] & p_age_imp < age.sexual.cessation)
d <- subset(d, age >= age.limits[1] & age < age.sexual.cessation)

l$comb.age <- l$age + l$p_age_imp
l$diff.age <- abs(l$age - l$p_age_imp)

l$duration.time <- l$duration * 7 / time.unit

#Append Data when geog.lvl is defined
if (!is.null(geog.lvl)) {
  d$geog <- epistats$geog.d
  d$geogYN <- epistats$geogYN.d
  l$geog <- epistats$geog.l
  l$geogYN <- epistats$geogYN.l
}

## Degree calculations ##

l$ONGOING <- as.numeric(l$ONGOING)
l$ongoing2 <- ifelse(is.na(l$ONGOING), 0, l$ONGOING)
l$ONGOING <- NULL

d <- l %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ptype == 1) %>%
  group_by(AMIS_ID) %>%
  summarise(deg.main = sum(ongoing2)) %>%
  right_join(d, by = "AMIS_ID")

d <- l %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ptype == 2) %>%
  group_by(AMIS_ID) %>%
  summarise(deg.casl = sum(ongoing2)) %>%
  right_join(d, by = "AMIS_ID")

# If missing degree, then set to 0
d$deg.main <- ifelse(is.na(d$deg.main), 0, d$deg.main)
d$deg.casl <- ifelse(is.na(d$deg.casl), 0, d$deg.casl)

# recoding to truncate degree
d$deg.casl <- ifelse(d$deg.casl > 3, 3, d$deg.casl)
d$deg.main <- ifelse(d$deg.main > 2, 2, d$deg.main)

d$deg.tot <- d$deg.main + d$deg.casl

# Concurrency
d$deg.main.conc <- ifelse(d$deg.main > 1, 1, 0)
d$deg.casl.conc <- ifelse(d$deg.casl > 1, 1, 0)

## one-off calcs ##

out$main <- list()
lmain <- l[l$ptype == 1, ]

lmain$index.age.grp <- cut(lmain$age, age.breaks, labels = FALSE,
                           right = FALSE, include.lowest = FALSE)
lmain$part.age.grp <- cut(as.numeric(lmain$p_age_imp), age.breaks, labels = FALSE,
                          right = FALSE, include.lowest = FALSE)

lmain$same.age.grp <- ifelse(lmain$index.age.grp == lmain$part.age.grp, 1, 0)

# overall
durs.main <- lmain %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ongoing2 == 1) %>%
  summarise(mean.dur = mean(duration.time, na.rm = TRUE),
            median.dur = median(duration.time, na.rm = TRUE)) %>%
  as.data.frame()

# create city weights
if (!is.null(geog.lvl)) {
  durs.main.geo <- lmain %>%
    filter(RAI == 1 | IAI == 1) %>%
    filter(ongoing2 == 1) %>%
    filter(geogYN == 1) %>%
    summarise(mean.dur = mean(duration.time, na.rm = TRUE),
              median.dur = median(duration.time, na.rm = TRUE)) %>%
    as.data.frame()

  # city-specific weight based on ratio of medians
  wt <- durs.main.geo$median.dur / durs.main$median.dur
} else {
  wt <- 1
}

# The dissolution rate is function of the mean of the geometric distribution
# which relates to the median as:
durs.main$rates.main.adj <- 1 - (2^(-1 / (wt * durs.main$median.dur)))

# Mean duration associated with a geometric distribution that median:
durs.main$mean.dur.adj <- 1 / (1 - (2^(-1 / (wt * durs.main$median.dur))))
out$main$durs.main.homog <- durs.main

# stratified by age

# first, non-matched by age group
durs.main.nonmatch <- lmain %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ongoing2 == 1) %>%
  filter(same.age.grp == 0) %>%
  summarise(mean.dur = mean(duration.time, na.rm = TRUE),
            median.dur = median(duration.time, na.rm = TRUE)) %>%
  as.data.frame()
durs.main.nonmatch$index.age.grp <- 0

# then, matched within age-groups
durs.main.matched <- lmain %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ongoing2 == 1) %>%
  filter(same.age.grp == 1) %>%
  group_by(index.age.grp) %>%
  summarise(mean.dur = mean(duration.time, na.rm = TRUE),
            median.dur = median(duration.time, na.rm = TRUE)) %>%
  as.data.frame()
durs.main.matched

durs.main.all <- rbind(durs.main.nonmatch, durs.main.matched)

durs.main.all$rates.main.adj <- 1 - (2^(-1 / (wt * durs.main.all$median.dur)))
durs.main.all$mean.dur.adj <- 1 / (1 - (2^(-1 / (wt * durs.main.all$median.dur))))

durs.main.all <- durs.main.all[, c(3, 1, 2, 4, 5)]
out$main$durs.main.byage <- durs.main.all

if (smooth.main.dur == TRUE) {
  n2 <- nrow(durs.main.all)
  n1 <- n2 - 1
  if (n2 > 3) {
    out$main$durs.main.byage$mean.dur.adj[n2] <-
      mean(out$main$durs.main.byage$mean.dur.adj[n1:n2])
  }
}

# If sexual cessation model, then set diss coef for age grp above boundary to 1
if (sex.cess.mod == TRUE) {
  index.age.grp <- max(out$main$durs.main.byage$index.age.grp) + 1
  df <- data.frame(index.age.grp = index.age.grp, mean.dur = 1, median.dur = 1,
                   rates.main.adj = 1, mean.dur.adj = 1)
  out$main$durs.main.byage <- rbind(out$main$durs.main.byage, df)
}

## Durations (CASUAL) ----
out$casl <- list()
lcasl <- l[l$ptype == 2, ]

lcasl$index.age.grp <- cut(lcasl$age, age.breaks, labels = FALSE, right = FALSE,
                           include.lowest = FALSE)
lcasl$part.age.grp <- cut(as.numeric(lcasl$p_age_imp), age.breaks,
                          right = FALSE, labels = FALSE, include.lowest = FALSE)

lcasl$same.age.grp <- ifelse(lcasl$index.age.grp == lcasl$part.age.grp, 1, 0)


# overall
durs.casl <- lcasl %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ongoing2 == 1) %>%
  summarise(mean.dur = mean(duration.time, na.rm = TRUE),
            median.dur = median(duration.time, na.rm = TRUE)) %>%
  as.data.frame()

# create city weights
if (!is.null(geog.lvl)) {
  durs.casl.geo <- lcasl %>%
    filter(RAI == 1 | IAI == 1) %>%
    filter(ongoing2 == 1) %>%
    filter(geogYN == 1) %>%
    summarise(mean.dur = mean(duration.time, na.rm = TRUE),
              median.dur = median(duration.time, na.rm = TRUE)) %>%
    as.data.frame()

  # city-specific weight based on ratio of medians
  wt <- durs.casl.geo$median.dur / durs.casl$median.dur
} else {
  wt <- 1
}

# The dissolution rate is function of the mean of the geometric distribution
# which relates to the median as:
durs.casl$rates.casl.adj <- 1 - (2^(-1 / (wt * durs.casl$median.dur)))

# Mean duration associated with a geometric distribution that median:
durs.casl$mean.dur.adj <- 1 / (1 - (2^(-1 / (wt * durs.casl$median.dur))))
out$casl$durs.casl.homog <- durs.casl

# stratified by age

# first, non-matched by age group
durs.casl.nonmatch <- lcasl %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(ongoing2 == 1) %>%
  filter(same.age.grp == 0) %>%
  # group_by(index.age.grp) %>%
  summarise(mean.dur = mean(duration.time, na.rm = TRUE),
            median.dur = median(duration.time, na.rm = TRUE)) %>%
  as.data.frame()
durs.casl.nonmatch$index.age.grp <- 0

# then, matched within age-groups
durs.casl.matched <- lcasl %>%
  filter(RAI == 1 | IAI == 1) %>%
  filter(same.age.grp == 1) %>%
  filter(ongoing2 == 1) %>%
  group_by(index.age.grp) %>%
  summarise(mean.dur = mean(duration.time, na.rm = TRUE),
            median.dur = median(duration.time, na.rm = TRUE)) %>%
  as.data.frame()

durs.casl.all <- rbind(durs.casl.nonmatch, durs.casl.matched)

durs.casl.all$rates.casl.adj <- 1 - (2^(-1 / (wt * durs.casl.all$median.dur)))
durs.casl.all$mean.dur.adj <- 1 / (1 - (2^(-1 / (wt * durs.casl.all$median.dur))))

durs.casl.all <- durs.casl.all[, c(3, 1, 2, 4, 5)]
out$casl$durs.casl.byage <- durs.casl.all

# If sexual cessation model, then set diss coef for age grp above boundary to 1
if (sex.cess.mod == TRUE) {
  index.age.grp <- max(out$casl$durs.casl.byage$index.age.grp) + 1
  df <- data.frame(index.age.grp = index.age.grp, mean.dur = 1, median.dur = 1,
                   rates.casl.adj = 1, mean.dur.adj = 1)
  out$casl$durs.casl.byage <- rbind(out$casl$durs.casl.byage, df)
}

