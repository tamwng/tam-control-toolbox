clear; clc; close all;

outdir = './brlspc/csm/ex5/results';
seed = 42;

run_ex5(struct('type','ones'), seed, outdir);
run_ex5(struct('type','linear'), seed, outdir);
run_ex5(struct('type','poly','degree',2), seed, outdir);
run_ex5(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
