% batch_ex1a.m
% Runs Example 1-appendix once per kernel with saturated control and saves results under ./results

clear; clc; close all;

outdir = './brlspc/csm/ex1/ex1app/results';
seed = 42;

run_ex1app_sensitivity(struct('type','poly','degree',2,'rho',1e-3), seed, outdir);
run_ex1app_sensitivity(struct('type','poly','degree',2,'rho',1e-2), seed, outdir);
run_ex1app_sensitivity(struct('type','poly','degree',2,'rho',1e-1), seed, outdir);
run_ex1app_sensitivity(struct('type','poly','degree',2,'rho',1), seed, outdir);
