function seq=truncexp_jitter_sample(min,max,mean,samples)
%randomly sample "samples" points from a exponential distribution
%paramenterized by "mean" and truncated by "min" and "max" (i.e. the lowest
%and the highest possible value in the sample are "min" and "max",
%respectively)

% ***note that the mean of the exponential distribution before truancation
% does not equal the mean after truncation!

%with mean=1.5, after truncating at [2.5 10], the after-truncation mean is
%about 4

%with mean=0.5, after truncatiing at [1 4], the after-truncation mean is about 1.5
y=makedist('Exponential','mu',mean);
t = truncate(y,min,max);
r = random(t,[samples,1]);
seq=r;

end