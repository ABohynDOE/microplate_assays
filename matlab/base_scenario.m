clear; clc;
%% Build base design
design = zeros(32,8);
% Basic factors a to e
for i=[1,2,3,4,5]
    a = 2^(5-i);
    b = 2^(i-1);
    design(:,i) = repmat([repelem(-1,a),repelem(1,a)],1,b);
end
% Factor f = abcde
design(:,6) = prod(design(:,[1,2,3,4,5]),2);
% Factor g = ace
design(:,7) = prod(design(:,[1,3,5]),2);
% Factor h = abc
design(:,8) = prod(design(:,[1,2,3]),2);

%% All TFI of the base design
tfi = zeros(32,nchoosek(8,2));
% All pairs of factors a to h
combs = nchoosek(1:8, 2);
for i=1:nchoosek(8,2)
    tfi(:,i) = prod(design(:,combs(i,:)),2);
end

thfi = zeros(32,nchoosek(8,3));
% All pairs of factors a to h
combs = nchoosek(1:8, 3);
for i=1:nchoosek(8,3)
    thfi(:,i) = prod(design(:,combs(i,:)),2);
end

%% Pseudo-factors for the columns
% Matrix of the 7 pseudo-factors
pf = zeros(32,7);
% p1 = ab
pf(:,1) = prod(design(:,[1,2]),2);
% p2 = ce
pf(:,2) = prod(design(:,[3,5]),2);
% p3 = acd
pf(:,3) = prod(design(:,[1,3,6]),2);
% p4 = p1 p2
pf(:,4) = prod(pf(:,[1,2]),2);
% p5 = p1 p3
pf(:,5) = prod(pf(:,[1,3]),2);
% p6 = p2 p3
pf(:,6) = prod(pf(:,[2,3]),2);
% p7 = p1 p2 p3
pf(:,7) = prod(pf(:,[1,2,3]),2);

%% Build the whole factorial effect matrix
% All ME, all 2FI , all 3TFI and all PF
factorial_effects = [design, pf, tfi, thfi];

%% Build vector with names
names = [[char(96 + (1:8))', blanks(8)', blanks(8)']; % ME names
    [repmat('p',7,1), char(48 + (1:7))', blanks(7)'] % PF names
    [char(nchoosek(96 + (1:8)', 2)), blanks(nchoosek(8,2))']; %TFI names
    char(nchoosek(96 + (1:8)', 3))]; %3FI names

%% Switch on diary to save output
delete base_scenario.txt;
diary base_scenario.txt;

%% Compute interaction between ME, 2FI, 3FI and PF for column positions
interaction = [design, pf, tfi]' * factorial_effects;
alias_covered = [];
for i=1:size(interaction,1)
    % Check if effect was already covered
    if ismember(i, alias_covered)
        continue
    end
    % Name of the effect
    fprintf('%s = ', names(i,:));
    alias = find(interaction(i,:) == 32);
    alias = alias(alias ~= i);
    alias_covered = [alias_covered, alias];
    for j=1:size(alias,2)
        fprintf(names(alias(1,j),:));
        if j < size(alias, 2)
            fprintf(' + ');
        end
    end
    fprintf('\n');
end

%% Define the 7 pseudo-factors coding the tubes
tube_pf = zeros(32,7);
% Tubes defined by h = abc so the seven pseudo-factor for the tubes are
% defined by p1 = a, p2 = b, p3= c and p4=p1p2, p5=p1p3, p6=p2p3 and p7 =
% p1p2p3
tube_pf(:,1:3) = design(:,[1,2,3]);
index = 4;
for i=[2,3]
   combs = nchoosek([1,2,3], i);
   for j=1:nchoosek(3,i)
        tube_pf(:, index) = prod(tube_pf(:,combs(j,:)), 2);
        index = index + 1;
   end
end

%% Compute aliasing in the week stratum 
% week stratum contains the week effect
week = design(:,8); % factor h
aliasing = week' * factorial_effects;
effects_index = find(aliasing == 32);
fprintf('\nWEEK:\n');
disp(strjoin(cellstr(names(effects_index, :)),' + '));

%% Compute aliasing in the plate stratum 
% Plate stratum contains the plate and week.plate effect
plate = zeros(32,2);
plate(:,1) = design(:,7); % factor g
plate(:,2) = week .* plate(:,1);
aliasing = plate' * factorial_effects;
fprintf('\nPLATE:\n');
for i=[1,2]
    effects_index = find(aliasing(i,:) == 32);
    disp(strjoin(cellstr(names(effects_index, :)),' + '));
end

%% Compute aliasing in the tube stratum 
% Tube stratum contains the 7 tube effects and the 7 week.tube effects
tube = zeros(32,14);
tube(:,1:7) = tube_pf;
tube(:,8:14) = week.*tube_pf;
aliasing = tube' * factorial_effects;
fprintf('\nTUBE:\n');
for i=1:7
    effects_index = find(aliasing(i,:) == 32);
    disp(strjoin(cellstr(names(effects_index, :)),' + '));
end

%% Compute aliasing in the unit stratum 
% Unit stratum contains the 7 plate.tube effects and the 7 week.plate.tube effects
unit = zeros(32,14);
unit(:,1:7) = plate(:,1).*tube_pf;
unit(:,8:14) = week.*unit(:,1:7);
aliasing = unit' * factorial_effects;
fprintf('\nUNIT:\n');
for i=1:7
    effects_index = find(aliasing(i,:) == 32);
    disp(strjoin(cellstr(names(effects_index, :)),' + '));
end

%% Switch off diary
diary off;



