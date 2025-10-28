% AL_thickness=200*1e-7;%active layer tickness

%% First Calculate the Recombination paramters of the CT and Exciton
%here we also calculate the absorption profile of the device and the
%emission spectra based on the properties of the states, 
% 
%% do not forget to install the symbolic math package*
Temp=300;
AL_thickness=100*1e-7;
Prec=paramsRec;%first initiliase the recombination parameters ( the parameters are set here by default and can be changed under or in the paramRec function
%below are a set of parameters that can be changed
Prec.params.Ex.DG0=1.63;
Prec.params.CT.f=5e-2;
offset=0.2;
tickness=AL_thickness*1e-2;%in m
Prec.params.CT.DG0=Prec.params.Ex.DG0-offset;
Prec.params.RCTE=1e-4;
Prec.params.Ex.Li=0.15;
Prec.params.CT.Li=0.15;
Prec.params.CT.L0=0.18;
Prec.params.Ex.f=5;
Prec.params.Excitondesnity=1e28;
Prec.params.Vstar=0.001;
Prec.const.T=300;
Prec.params.CT.sigma=0.04;
Prec.params.Ex.sigma=0.02;
Prec.params.Ex.numbrestate=1;
Prec.params.CT.numbrestate=1;
Prec=paramsRec.calcall(Prec, tickness);%this line calculated the different properties of the states (pass thickness)
krecCT=Prec.params.CT.results.knr;krecex=Prec.params.Ex.results.knr;
Voc=Prec.results.Vocrad-Prec.results.Dvnr;

%% in this part we generate a device with a certain number of properties
%the default properties are set in pnParamsHCT or in the excel file p3hTPCBM.xlsx

NC=2e19;activelayer=2;Kfor=1e-11;%V in V, K in S-1, NC in Cm-3, Jsc in mA cm-2,
mobility=3e-4;kdis=1.3e10;kdisex=1e11;% Tq1 in s,mobility in Cm2V-1s-1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
deviceParameterFile='DeviceParameters_Default.xlsx';
DP = deviceparams(['parameters\',deviceParameterFile]);

DP.light_properties.OM=0;%to consider the transfer matrix generation profile
DP.Time_properties.tpoints=100;
DP.Layers{activelayer}.tp=AL_thickness;
DP=DP.generateDeviceparams(NC,activelayer,mobility,kdis,kdisex,Prec,1e-11,0);
clear NC activelayer Tq1exp mobility kdis kdisex
%% Run the JV scans here
Vstart=0;Vend=2;
tic
DP.Layers{2}.r0=0; %R0 for field dependence is 1 nm

DV2=device(DP);

DV2=device.runsolJsc(DV2,1);
    toc
    
    tic
    DV2=device.runsolJV(DV2,1,Vstart,Vend);
    toc

    assignin('base',"DV_infinite",DV2)
    figure(2)
dfplot.JV_new(DV2.sol_JV(1),1)
hold on
lg=legend();
lg.String{end}='infinite';
%%
clear EL_maxint PL_maxint
close all
kk=0;
variablelist=[300,250,200,150,100];
for Var_name=variablelist
    DP.External_prop.Rseries=0;
    DP.Experiment_prop.BC =3;
    Prec.const.T=Var_name;
    Prec=paramsRec.calcall(Prec);%this line calculated the different properties of the states.

    sn=1e5;
    DP.External_prop.sn_l=sn;%left Electron extraction/surface recombination coefficient in cm s^-1
    DP.External_prop.sn_r=sn;%right Electron extraction/surface recombination coefficient in cm s^-1
    DP.External_prop.sp_l=sn;%left hole extraction/surface recombination coefficient in cm s^-1
    DP.External_prop.sp_r=sn;%right hole extraction/surface recombination coefficient in cm s^-1
    tic
    NC=2e19;activelayer=2;Kfor=1e-11;%V in V, K in S-1, NC in Cm-3, Jsc in mA cm-2,
    mobility=1e-3*exp(-0.04/0.026*300/Var_name)
    kdis=1.3e10;kdisex=5e9;% Tq1 in s,mobility in Cm2V-1s-1
    DP=DP.generateDeviceparams(NC,activelayer,mobility,kdis,kdisex,Prec,1e-11,0);

    DV2=device(DP);
    DV2.Prec=Prec;
    toc
    
    G=1e-6;
    tic
    DV2=device.runsolJsc(DV2,G);
    toc
    
    tic
    DV2=device.runsolJV(DV2,G,Vstart,Vend);
    toc
    G=1;
    tic
    DV2=device.runsolJsc(DV2,G);
    toc
    
    tic
    DV2=device.runsolJV(DV2,G,Vstart,Vend);
    toc
    assignin('base',"DV_MT"+num2str(Var_name),DV2)
    
    %%
    kk=kk+1;
    figure(2)
    subplot(2,2,1)
dfplot.JV_new(DV2.sol_JV(1),1)
ax=gca;
ax.YScale='log';
ax.YLim=[0,1e-1];
hold on
lg=legend();
lg.String{end}=num2str(Var_name);%num2str(log(Rseries)/log(10));
subplot(2,2,2)
[~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,0.01,num2str(Var_name));
EL_maxint(kk)=max(ELplot);
hold on 
xlim([0.9,1.8])

subplot(2,2,3)
[~,PLplot,~]=dfplot.photoluminescence_mult(DV2,2,1,1,num2str(Var_name));
xlim([0.9,1.8])
PL_maxint(kk)=max(PLplot);
hold on 

subplot(2,2,4)
plot(variablelist(1:kk),PL_maxint/max(PL_maxint))
hold on
plot(variablelist(1:kk),EL_maxint/max(EL_maxint))
hold off
legend('maxPL','maxEL')
end

%% Plot the results for the series resitance

close all
kk=0;
clear EL_maxint PL_maxint
variablelist=[1,100,500,1000];

for Var_name=variablelist
    kk=kk+1;
    eval("DV2=DV_R"+num2str(Var_name));
   figure(2)
    subplot(2,2,1)
dfplot.JV_new(DV2.sol_JV(1),1)
ax=gca;
ax.YScale='log';
ax.YLim=[1e-7,1e-1];
ax.XLim=[0,2];
hold on
lg=legend();
lg.String{end}=num2str(Var_name);%num2str(log(Rseries)/log(10));
lg.Title.String='series resitance ohm cm-2';
title('dark JV')
subplot(2,2,2)
[~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,0.1,num2str(Var_name));
EL_maxint(kk)=max(ELplot);
hold on 
xlim([0.9,2])
lg=legend;
lg.Title.String='series resitance ';
subplot(2,2,3)
[~,PLplot,~]=dfplot.photoluminescence_mult(DV2,2,0.5,1e-6,num2str(Var_name));
xlim([0.9,2])
PL_maxint(kk)=max(PLplot);
hold on 
lg=legend;
lg.Title.String='series resitance';
subplot(2,2,4)
plot(variablelist(1:kk),PL_maxint/max(PL_maxint),'*-')
hold on
plot(variablelist(1:kk),EL_maxint/max(EL_maxint),'o-')
hold off
ylim([0,1.1])
legend('maxPL','maxEL')
 xlabel('series resitance (ohm cm-2)')
 ax=gca;
 ax.XScale='log';
end
%% Plot the results for the shunt resitance
close all
kk=0;
clear EL_maxint PL_maxint
variablelist=[100,500,1000,5000,10000];
eval("DV2=DV_1;");
for Var_name=variablelist
    kk=kk+1;
%     eval("DV2=DV_R"+num2str(Rseries));
   figure(2)
    subplot(2,2,1)
dfplot.JV_new(DV2.sol_JV(1),1,Var_name)
ax=gca;
ax.YScale='log';
ax.YLim=[1e-7,1e-1];
ax.XLim=[0,2];
hold on
lg=legend();
lg.String{end}=num2str(Var_name);%num2str(log(Rseries)/log(10));
lg.Title.String='shunt resitance ohm cm-2';
title('dark JV')
subplot(2,2,2)
[~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,2,num2str(Var_name),Var_name);
EL_maxint(kk)=max(ELplot);
hold on 
xlim([0.9,2])
lg=legend;
lg.Title.String='shunt resitance ';
subplot(2,2,3)
[~,PLplot,~]=dfplot.photoluminescence_mult(DV2,2,0.5,1e-6,num2str(Var_name));
xlim([0.9,2])
PL_maxint(kk)=max(PLplot);
hold on 
lg=legend;
lg.Title.String='shunt resitance';
subplot(2,2,4)
plot(variablelist(1:kk),PL_maxint/max(PL_maxint),'*-')
hold on
plot(variablelist(1:kk),EL_maxint/max(EL_maxint),'o-')
hold off
ylim([0,1.1])
legend('maxPL','maxEL')
 xlabel('shunt resitance (ohm cm-2)')
 ax=gca;
 ax.XScale='log';
end

%% Plot the results for the mobility
kk=0;
clear EL_maxint PL_maxint EL_maxint_05 EL_maxint_1 EL_maxint_2
variablelist=[1,5,10,50,100];
 
for Var_name=variablelist
    kk=kk+1;
    eval("DV2=DV_MT"+num2str(Var_name));
  figure(2)
    subplot(2,2,1)
dfplot.JV_new(DV2.sol_JV(1),1)
ax=gca;
ax.YScale='log';
ax.YLim=[1e-7,1e-1];
ax.XLim=[0,2];
hold on
lg=legend();
lg.String{end}=num2str(mobility/Var_name,'%1.0e');%num2str(log(Rseries)/log(10));
lg.Title.String='mobility  ohm cm2 V-1 s-1';
title('dark JV')
subplot(2,2,2)
[~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,2,num2str(mobility/Var_name,'%1.0e'));
EL_maxint_2(kk)=max(ELplot);
hold on 

xlim([0.9,2])
lg=legend;
lg.Title.String='mobility ';
subplot(2,2,3)
[~,PLplot,~]=dfplot.photoluminescence_mult(DV2,2,0,1e-6,num2str(mobility/Var_name,'%1.0e'));
xlim([0.9,2])
PL_maxint(kk)=max(PLplot);
hold on 
lg=legend;
lg.Title.String='mobility';
subplot(2,2,4)
plot(mobility./variablelist(1:kk),PL_maxint/max(PL_maxint),'*-')
hold on
plot(mobility./variablelist(1:kk),EL_maxint_2/max(EL_maxint_2),'o-')
hold off
ylim([0,1.1])
figure(3)
[~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,1,num2str(mobility/Var_name,'%1.0e'));
EL_maxint_1(kk)=max(ELplot);
[~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,0.5,num2str(mobility/Var_name,'%1.0e'));
EL_maxint_05(kk)=max(ELplot);
% [~,ELplot]=dfplot.Electroluminescence_multi(DV2,2,0,5,num2str(mobility/Rseries,'%1.0e'));
% EL_maxint_5(kk)=max(ELplot);
figure(2)
subplot(2,2,4)
plot(mobility./variablelist(1:kk),PL_maxint/max(PL_maxint),'*-')
hold on
% plot(mobility./variablelist(1:kk),EL_maxint_5/max(EL_maxint_5),'o-')
plot(mobility./variablelist(1:kk),EL_maxint_2/max(EL_maxint_2),'o-')
plot(mobility./variablelist(1:kk),EL_maxint_1/max(EL_maxint_1),'o-')

plot(mobility./variablelist(1:kk),EL_maxint_05/max(EL_maxint_05),'o-')

hold off
ylim([0,1.1])
legend('maxPL','maxEL at 2mA','maxEL at 1mA','maxEL at 0.5mA')
 xlabel('mobility ( cm2 V-1s-1)')
 ax=gca;
 ax.XScale='log';
end
    