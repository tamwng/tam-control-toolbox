% batch_ex2a.m
% Runs Example 2a once per kernel and saves results under ./results

clear; clc; close all;

outdir = './brlspc/csm/ex2/ex2a/results';
seed = 42;

run_ex2a_kernel(struct('type','ones'), seed, outdir);
run_ex2a_kernel(struct('type','linear'), seed, outdir);
run_ex2a_kernel(struct('type','poly','degree',2), seed, outdir);
run_ex2a_kernel(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
