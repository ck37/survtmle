library(survtmle)
library(survival)
context("Testing hazard_tmle function")

test_that("hazard_tmle with bounds of (0,1) gives same results as unbounded with one failure type", {
	set.seed(1234)
	n <- 200
	trt <- rbinom(n,1,0.5)
	adjustVars <- data.frame(W1 = round(runif(n)), W2 = round(runif(n,0,2)))
	
	ftime <- round(1 + runif(n,1,4) - trt + adjustVars$W1 + adjustVars$W2)
	ftype <- round(runif(n,0,1))
	
	# fit with no bounds
	fit1 <- survtmle(ftime = ftime, ftype = ftype, trt = trt, adjustVars = adjustVars,
	glm.trt = "W1 + W2", 
	glm.ftime = "trt + W1 + W2", glm.ctime = "trt + W1 + W2", 
	method="hazard", t0=6)
	# fit with bounds
	bf <- data.frame(t=1:6,l1 = rep(0,6),u1 = rep(1,6))
	fit2 <- survtmle(ftime = ftime, ftype = ftype, trt = trt, adjustVars = adjustVars,
	glm.trt = "W1 + W2", 
	glm.ftime = "trt + W1 + W2", glm.ctime = "trt + W1 + W2", 
	method="hazard", t0=6, bounds = bf)

	# should have roughly same point estimates
	expect_true(all(abs(fit1$est - fit2$est) < 1e-5))
})

test_that("hazard_tmle with bad bounds gives good result", {
	# setwd("~/Dropbox/R")
	# devtools::build("survtmle")
	# install.packages("survtmle", repos = NULL, type="source")
	# library(survtmle)
	set.seed(1234)
	n <- 200
	trt <- rbinom(n,1,0.5)
	adjustVars <- data.frame(W1 = round(runif(n)), W2 = round(runif(n,0,2)))
	
	ftime <- round(1 + runif(n,1,4) - trt + adjustVars$W1 + adjustVars$W2)
	ftype <- round(runif(n,0,1))
	
	# bounds that are outside of range of observed data
	bf <- data.frame(t=1000:1005,l1 = rep(0,6),u1 = rep(1,6))
	fit2 <- survtmle(ftime = ftime, ftype = ftype, trt = trt, adjustVars = adjustVars,
	glm.trt = "W1 + W2", 
	glm.ftime = "trt + W1 + W2", glm.ctime = "trt + W1 + W2", 
	method="hazard", t0=6, bounds = bf)

	# should have roughly same point estimates
	expect_true(all(!is.na(fit2$est)))
})

test_that("hazard_tmle and mean_tmle equal kaplan-meier with no covariates", {
	set.seed(1234)
	n <- 500
	trt <- rbinom(n,1,0.5)
	adjustVars <- data.frame(W1 = round(runif(n)), W2 = round(runif(n,0,2)))
	
	ftime <- round(runif(n,0,4)) + 1
	ftype <- round(runif(n,0,1))
	
	# hazard fit
	suppressWarnings(
	fit1 <- survtmle(ftime = ftime, ftype = ftype, trt = trt, adjustVars = adjustVars,
	glm.trt = "1", 
	glm.ftime = paste0("trt + ",paste0("I(t==",1:max(ftime),")",collapse="+"),"+",paste0("I(trt*t==",1:max(ftime),")",collapse="+")),
	glm.ctime = paste0("trt + ",paste0("I(t==",1:max(ftime),")",collapse="+"),"+",paste0("I(trt*t==",1:max(ftime),")",collapse="+")), 
	method="hazard", t0=5)
	)
	# mean fit
	fit2 <- survtmle(ftime = ftime, ftype = ftype, trt = trt, adjustVars = adjustVars,
	glm.trt = "1", 
	glm.ftime = "trt", 
	glm.ctime = "trt", 
	method="mean", t0=5)

	# compare to kaplan meier
	km <- 1-summary(survfit(Surv(ftime,ftype)~trt))$surv[c(5,10)]

	expect_equal(km,as.numeric(fit1$est))
	expect_equal(km,as.numeric(fit2$est))
})