% batch_ex2b.m
% Runs Example 2b once per kernel and saves results under ./results

clear; clc; close all;

outdir = './brlspc/csm/ex2/ex2b/frequency/results';
seed = 42;

omega_step = 0.05;
run_ex2b_kernel(struct('type','ones'), seed, outdir, omega_step);
run_ex2b_kernel(struct('type','rbf','sigma',1e4,'q',1), seed, outdir, omega_step);