% Copyright 2010 George F. Burkhard, Eric T. Hoke, Stanford University

% This program calculates the field profile, exciton generation profile
% and generated current from the wavelength dependent complex indicies of
% refraction in devices using the transfer matrix method. It assumes the light source
% light source is in an n=1 environment (air) and that the first layer is
% a thick superstrate, so that incoherent reflection from the air/1st layer
% interface is taken into account before the coherent interference is
% calculated in the remaining layers. If there is no thick superstrate, 
% input 'Air' as the first layer so that the incoherent reflection calculates
% to 0. 
% The program also returns the calculated short circuit current for the device in 
% mA/cm^2 if the device had an IQE of 100%.

% The procedure was adapted from J. Appl. Phys Vol 86, No. 1 (1999) p.487
% and JAP 93 No. 7 p. 3693.

% George Burkhard and Eric Hoke February 5, 2010
% When citing this work, please refer to:
%
% G. F. Burkhard, E. T. Hoke, M. D. McGehee, Adv. Mater., 22, 3293.
% Accounting for Interference, Scattering, and Electrode Absorption to Make
% Accurate Internal Quantum Efficiency Measurements in Organic and Other 
% Thin Solar Cells

% Modifications:
% 3/3/11 Parastic absorption (parasitic_abs) is calculated and made
% accessable outside of script.  
% 3/5/15 Improved precision of fundamental constants


function [Xpos,Gx]=TransferMatrix_generation(activelayertickness,name,lightinesity)
%------------BEGIN USER INPUT PARAMETERS SPECITIFCATION---------------
%
lambda=350:1000; % Wavelengths over which field patterns are calculated
stepsize = 1;   % The electric field is calculated at a latice of points (nm)
                % in the device cross section seperated by this distance
%lightinesity in sun equivalent
% Specify Layers in device (an arbitrary number of layers is permitted) and 
% thicknesses.
%
layers = { 'quartz1' 'ITO' 'ZnO' name 'MO' 'Ag'}; % Names of layers of materials starting from side light is incident from
thicknesses = [1000 100 25 activelayertickness 10 150];  % thickness of each corresponding layer in nm (thickness of the first layer is irrelivant)
% Set plotGeneration to 'true' if you want to plot generation rate as a
% function of position in the device and output the calculated short circuit current
% under AM1.5G illumination (assuming 100% internal quantum efficiency)
activeLayer = 4; % index of material layer where photocurrent is generated
folder='\optical_data';
%
%------------END USER INPUT PARAMETERS SPECIFICATION-------------------



% Load in index of refraction for each material
n = zeros(size(layers,2),size(lambda,2));
for index = 1:size(layers,2)
    n(index,:) = LoadRefrIndex(folder,layers{index},lambda);
end
t = thicknesses;

% Physical constants (CODATA 2018 values)
h = 6.62607015e-34;     % Planck constant [J s]
c = 2.99792458e8;       % Speed of light [m s^-1]
q = 1.602176634e-19;    % Elementary charge [C]

% Calculate Incoherent power transmission through substrate
% See Griffiths "Intro to Electrodynamics 3rd Ed. Eq. 9.86 & 9.87
R_glass=abs((1-n(1,:))./(1+n(1,:))).^2;

% Calculate transfer matrices, and field at each wavelength and position
t(1)=0;
t_cumsum=cumsum(t);
x_pos=(stepsize/2):stepsize:sum(t); %positions to evaluate field
%x_mat specifies what layer number the corresponding point in x_pos is in:
x_mat= sum(repmat(x_pos,length(t),1)>repmat(t_cumsum',1,length(x_pos)),1)+1; 
R=lambda*0;
E=zeros(length(x_pos),length(lambda));
for l = 1:length(lambda)
    % Calculate transfer matrices for incoherent reflection and transmission at the first interface
    S=I_mat(n(1,l),n(2,l));
    for matindex=2:(length(t)-1)
        S=S*L_mat(n(matindex,l),t(matindex),lambda(l))*I_mat(n(matindex,l),n(matindex+1,l));
    end
    R(l)=abs(S(2,1)/S(1,1))^2; %JAP Vol 86 p.487 Eq 9 Power Reflection from layers other than substrate
    T(l)=abs(2/(1+n(1,l)))/sqrt(1-R_glass(l)*R(l)); %Transmission of field through glass substrate Griffiths 9.85 + multiple reflection geometric series

    % Calculate all other transfer matrices
    for material = 2:length(t) 
        xi=2*pi*n(material,l)/lambda(l);
        dj=t(material);
        x_indices=find(x_mat == material); %indices of points which are in the material layer considered
        x=x_pos(x_indices)-t_cumsum(material-1); %distance from interface with previous layer
        % Calculate S matrices (JAP Vol 86 p.487 Eq 12 and 13)
        S_prime=I_mat(n(1,l),n(2,l));
        for matindex=3:material
            S_prime=S_prime*L_mat(n(matindex-1,l),t(matindex-1),lambda(l))*I_mat(n(matindex-1,l),n(matindex,l));
        end
        S_doubleprime=eye(2);
        for matindex=material:(length(t)-1)
            S_doubleprime=S_doubleprime*I_mat(n(matindex,l),n(matindex+1,l))*L_mat(n(matindex+1,l),t(matindex+1),lambda(l));
        end
        % Normalized Field profile (JAP Vol 86 p.487 Eq 22)
        E(x_indices,l)=T(l)*(S_doubleprime(1,1)*exp(-1i*xi*(dj-x))+S_doubleprime(2,1)*exp(1i*xi*(dj-x))) ./(S_prime(1,1)*S_doubleprime(1,1)*exp(-1i*xi*dj)+S_prime(1,2)*S_doubleprime(2,1)*exp(1i*xi*dj));
    end 
end
% Absorption coefficient in cm^-1 (JAP Vol 86 p.487 Eq 23)
a=zeros(length(t),length(lambda));
for matindex=2:length(t)
     a(matindex,:)=4*pi*imag(n(matindex,:))./(lambda*1e-7);
end

% Plots generation rate as a function of position in the device and
% calculates Jsc 
    % Load in 1sun AM 1.5 solar spectrum in mW/cm2nm
    AM15_data=xlsread('AM15.xls');
    AM15=interp1(AM15_data(:,1), AM15_data(:,2), lambda, 'linear', 'extrap');
    AM15_intensity=AM15*lightinesity;
    % Energy dissipation mW/cm3-nm at each position and wavelength (JAP Vol
    % 86 p.487 Eq 22)
    ActivePos=find(x_mat == activeLayer);
    Q=repmat(a(activeLayer,:).*real(n(activeLayer,:)).*AM15_intensity,length(ActivePos),1).*(abs(E(ActivePos,:)).^2);

    % Exciton generation rate per second-cm3-nm at each position and wavelength
    Gxl=(Q*1e-3).*repmat(lambda*1e-9,length(ActivePos),1)/(h*c);
%     Gxl=1.*repmat(lambda*1e-9,length(ActivePos),1)/(h*c);

    if length(lambda)==1
        lambdastep= 1;
    else
        lambdastep=(max(lambda)-min(lambda))/(length(lambda)-1);
    end
    Gx=sum(Gxl,2)*lambdastep; % Exciton generation rate as a function of position/(sec-cm^3)
    % outputs predicted Jsc under AM1.5 illumination assuming 100% internal
    % quantum efficiency at all wavelengths
    Jsc=sum(Gx)*stepsize*1e-7*q*1e3; %in mA/cm^2
   
    % sends absorption, reflection, and wavelength data to the workspace   
    Xpos=x_pos(ActivePos)-min(x_pos(ActivePos));
    


%------------------- Helper Functions ------------------------------------
% Function I_mat
% This function calculates the transfer matrix, I, for reflection and
% transmission at an interface between materials with complex dielectric 
% constant n1 and n2.
function I = I_mat(n1,n2)
r=(n1-n2)/(n1+n2);
t=2*n1/(n1+n2);
I=[1 r; r 1]/t;

% Function L_mat
% This function calculates the propagation matrix, L, through a material of
% complex dielectric constant n and thickness d for the wavelength lambda.
function L = L_mat(n,d,lambda)
xi=2*pi*n/lambda;
L=[exp(-1i*xi*d) 0; 0 exp(1i*xi*d)];

% Function LoadRefrIndex
% This function returns the complex index of refraction spectra, ntotal, for the
% material called 'name' for each wavelength value in the wavelength vector
% 'wavelengths'.  The material must be present in the index of refraction
% library 'Index_of_Refraction_library.xls'.  The program uses linear
% interpolation/extrapolation to determine the index of refraction for
% wavelengths not listed in the library.
function ntotal = LoadRefrIndex(folder,name,wavelengths)

%Data in IndRefr, Column names in IndRefr_names
% [IndRefr,IndRefr_names]=xlsread('Index_of_Refraction_library.xls');
nkfile=fopen([pwd folder '\' name '_nk.txt']);
nkarray=textscan(nkfile,'%f %f %f','HeaderLines', 0);
fclose(nkfile);
% Load index of refraction data in spread sheet, will crash if misspelled
file_wavelengths=nkarray{1}*1e9;%IndRefr(:,strmatch('Wavelength',IndRefr_names));
n=nkarray{2};%IndRefr(:,strmatch(strcat(name,'_n'),IndRefr_names));
k=nkarray{3};%IndRefr(:,strmatch(strcat(name,'_k'),IndRefr_names));
% Interpolate/Extrapolate data linearly to desired wavelengths
n_interp=interp1(file_wavelengths, n, wavelengths, 'linear', 'extrap');
k_interp=interp1(file_wavelengths, k, wavelengths, 'linear', 'extrap');
%Return interpolated complex index of refraction data
ntotal = n_interp+1i*k_interp; 
