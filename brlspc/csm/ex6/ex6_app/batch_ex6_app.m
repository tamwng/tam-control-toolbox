clear; clc; close all;

outdir = './brlspc/csm/ex6/ex6_app/results';
seed = 42;

run_ex6_app(struct('type','ones'), seed, outdir);
run_ex6_app(struct('type','linear'), seed, outdir);
run_ex6_app(struct('type','poly','degree',2), seed, outdir);
run_ex6_app(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
