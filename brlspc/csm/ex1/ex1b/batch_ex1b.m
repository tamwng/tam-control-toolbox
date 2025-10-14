% batch_ex1a.m
% Runs Example 1b once per kernel with saturated control and saves results under ./results

clear; clc; close all;

outdir = './brlspc/csm/ex1/ex1b/results';
seed = 42;

run_ex1b_kernel(struct('type','ones'), seed, outdir);
run_ex1b_kernel(struct('type','linear'), seed, outdir);
run_ex1b_kernel(struct('type','poly','degree',2), seed, outdir);
run_ex1b_kernel(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
