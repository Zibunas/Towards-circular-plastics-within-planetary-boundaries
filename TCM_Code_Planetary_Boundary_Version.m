%% Disclaimer
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% This software represents the computational structure for the
% adjusted Technology Choice Model used in the following publication:
% ---------------------------------------------------------------------------
% Towards circular plastics within planetary boundaries
% by Marvin Bachmann (a), Christian Zibunas (a), Jan Hartmann (a), Victor Tulus (b), 
% Sangwon Suh (c), Gonzalo Guillén-Gosálbez (b), and André Bardow (d,*)
% a - Institute for Technical Thermodynamics, RWTH Aachen University, 52062 Aachen, Germany.
% b - Institute for Chemical and Bioengineering, Department of Chemistry and Applied Biosciences, ETH Zürich, 8093 Zurich, Switzerland.
% c - Bren School of Environmental Science and Management, University of California, Santa Barbara, CA 93117, USA.
% d - Energy and Process Systems Engineering, ETH Zürich, 8092 Zurich, Switzerland.
% *corresponding author: abardow@ethz.ch
% ---------------------------------------------------------------------------
% Since the plastics industry model cannot be published publicly due to licensing agreements
% with IHS Markit, we used the original case study by Kätelhön et al. (2016) and extended it 
% to include Planetary Boundaries. The plastics industry model can be shared with other IHS 
% Markit licensees. Please contact the corresponding author for details. 

% A detailed description of the original Technology Choice Model is provided in 
% Kätelhön et al. (2016), Stochastic Technology Choice Model for Consequential 
% Life Cycle Assessment Environ. Sci. Technol. 2016, 50, 23, 12575–12583

%% Setup
clear all
close all
clc

% Import data from excel file 'TCM_Case_Study_Data_Planetary_Boundary_Version.xlsx'
filename = 'TCM_Case_Study_Data_Planetary_Boundary_Version.xlsx';
% Matrix
A    = xlsread(filename,2); % Technology Matrix
B    = xlsread(filename,3); % Elementary Flow Fatrix
Q_PB = xlsread(filename,4); % Planetary Boundary Characterization Matrix
F    = xlsread(filename,5); % Factor constraints matrix
% Vector
y   = xlsread(filename,6); % Final Demand Vector
c   = xlsread(filename,7); % Factor Constraints Vector
SOS = xlsread(filename,8); % Safe operating space

Process_names = {'Rice factory';'Rice farming';'Low-nitrogen Rice farming';'Rice husk boiler';...
    'Natural gas boiler';'Wood pellet boiler';'Rice husk collection 1';'Rice husk collection 2';...
    'Rice husk collection 3';'Rice husk collection 4';'Rice husk collection 5';'Natural gas supply';...
    'Wood pellet supply';'Burning of rice husk';'Power plant';'Transportation by truck'}; % Process names for figure legend

PB_names = {'Climate change','Ocean acidification','Biosphere integrity change','Nitrogen cycle','Phosphorus cycle','Atmospheric aerosol loading','Freshwater use','Stratospheric ozone depletion','Land-system change'};
PB_names = cellfun(@(x) strrep(x,' ','\newline'), PB_names,'UniformOutput',false); % Planetary boundary category names for figure legend

% Define safe operating space
Share_global = 1e-5;            % Share of global economy, generic value
SoSOS = SOS * Share_global;     % Share of safe operating space
max_transgression = 12;         % Generic value to demonstate planetary boundary constraint for maximum transgression
max_transgression_category = 4; % Defines nitrogen cycle as the category to be limited

%% Optimization
% Define additional planetary boundary constraints
Inequal_matrix = vertcat(F,Q_PB(max_transgression_category,:)*B);             % Adds the nitrogen cycle to the constraints
Inequal_vec = vertcat(c,max_transgression*SoSOS(max_transgression_category)); % Sets limit for nitrogen cycle

% Parameters for linear programming
PF_CC = Q_PB(1,:) * B;    % Objective function, here defined as climate change planetary footprint 
lb = zeros(length(A), 1); % Lower bounds for s

% Linear programming
s_CC   = linprog(PF_CC, F, c, A, y, lb);                        % Climate-optimal solution
s_lowN = linprog(PF_CC, Inequal_matrix, Inequal_vec, A, y, lb); % Climate-optimal solution with constraint nitrogen cycle

% Post processing
PF_opt_contri      = Q_PB * B .* s_CC';         % Planetary footprints of climate-optimal solution
PF_opt_contri_norm = PF_opt_contri ./ (SOS);  % Normalized planetary footprints of climate-optimal solution

PF_lowN_contri      = Q_PB * B .* s_lowN';         % Planetary footprints of climate-optimal solution
PF_lowN_contri_norm = PF_lowN_contri ./ (SOS); % Normalized planetary footprints of climate-optimal solution

%% Plot
figure('WindowState','maximized') % plot for climate-optimal solution
b1 = bar(PF_opt_contri_norm,'stacked','FaceColor','flat');
ylabel('Planetary footprints in % of the global SOS')
hold
yline(Share_global,'--','Share of safe operating space','Color','red','LineWidth',1) %works only from version R2022a on
xticklabels(PB_names)
ylim([0 1.8e-4])
legend(Process_names)
set(b1(2),'facecolor',[87/255 171/255 39/255])
set(b1(4),'facecolor',[246/255 168/255 0/255])
set(b1(14),'facecolor',[204/255 7/255 30/255])
set(b1(15),'facecolor',[0/255 84/255 159/255])
set(b1(16),'facecolor',[122/255 111/255 172/255])
set(b1([1,3,5:13]),'facecolor',[156/255 158/255 159/255])

figure('WindowState','maximized') % plot for climate-optimal solution with nitrogen constraints
b2 = bar(PF_lowN_contri_norm,'stacked');
ylabel('Planetary footprints in % of the global SOS')
yline(Share_global,'--','Share of safe operating space','Color','red','LineWidth',1) %works only from version R2022a on
xticklabels(PB_names)
ylim([0 1.8e-4])
legend(Process_names)
set(b2(2),'facecolor',[87/255 171/255 39/255])
set(b2(3),'facecolor',[189/255 205/255 0/255])
set(b2(4),'facecolor',[246/255 168/255 0/255])
set(b2(14),'facecolor',[204/255 7/255 30/255])
set(b2(15),'facecolor',[0/255 84/255 159/255])
set(b2(16),'facecolor',[122/255 111/255 172/255])
set(b2([1,5:13]),'facecolor',[100/255 100/255 100/255])