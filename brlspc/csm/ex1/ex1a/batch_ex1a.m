% batch_ex1a.m
% Runs Example 1a once per kernel and saves results under ./results

clear; clc;

outdir = './brlspc/csm/ex1/ex1a/results';
seed = 42;

run_ex1a_kernel(struct('type','linear'), seed, outdir);
run_ex1a_kernel(struct('type','poly','degree',2), seed, outdir);
run_ex1a_kernel(struct('type','rbf','sigma',1.0), seed, outdir);
