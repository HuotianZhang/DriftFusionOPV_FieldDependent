%% first set the parameters for the recombination model

Prec                        = paramsRec;                    % initiliase the recombination parameters (default values)
% fixed model parameters for the efficiency limit exploration
tickness                    = 100 * 1e-9;
Prec.params.Ex.f            = 3;Prec.params.CT.f            = 1e-2;
Prec.params.Ex.sigma        = 0.0001;Prec.params.CT.sigma        = 0.0001;
Prec.params.Ex.numbrestate  = 1;Prec.params.CT.numbrestate  = 1;
Prec.params.Ex.L0           = 0.10;  Prec.params.CT.L0           = 0.1;
Prec.params.Ex.Li           = 0.1;   Prec.params.CT.Li           = 0.1;   %0.15
Prec.params.Vstar           = 0.000;
%state density parameter
Prec.params.Excitondesnity  = 8e27; %in m-3
Prec.params.RCTE            = 0.1;
Prec.const.Edistribution=0.5:0.005:3;%the energy distribution for the absorption spectra%need to be linearly spaced

%energetics that will be changed along the exploration of the highest
%efficiency
offset_LECT=0.1;
Prec.params.Ex.DG0          = 2.5;Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset_LECT;

Prec.const.T                = 300;
Prec                        = paramsRec.calcall(Prec, tickness); % Update the Recombination Parameters (pass thickness)
%% initialise the device parameters


deviceParameterFile = 'DeviceParameters_Default.xlsx';
DP = deviceparams(['parameters\',deviceParameterFile]);
activelayer = 2;
DP.light_properties.OM      = 0; %to consider the transfer matrix generation profile
DP.Time_properties.tpoints  = 100;
DP.Layers{activelayer}.tp   = tickness * 100; % [cm] = [m] * 100 - Store thickness in deviceparams
% Active Layer Index                % integer
NC          = 5e19;    %set to the same degeneracy as the CT state
mobility    = 1e-3;     % Charge Carrier Mobility           % cm^2 / V / s
%parameters to calculate the rates of dissociation of Exciton and CT state
Hab_CT_dis=0.004;
L0_CT_dis=0.11;
Hab_LE_dis=0.03;
L0_LE_dis=0.54;
marcusrate =  @(Hab,L0,x) Hab^2*exp(-(-x+L0).^2/0.026/4/L0)/sqrt(4*pi*L0*0.026)/6.62e-34*1.6e-19;

offset_CTCS=-0;
ECS=Prec.params.CT.DG0-offset_CTCS;

DP=DP.generateDeviceparams(NC,activelayer,mobility,0,0,Prec,ECS,4,Hab_CT_dis,L0_CT_dis,marcusrate,Hab_LE_dis,L0_LE_dis);

%%


offset_LECS=0.2;
for Li=0.15%0.06:0.01:0.1
    Prec.params.Ex.Li           = Li;
    counter=1;
    cases={'dropLECT','middlepoint','dropCTCS'};
    
    for offset_CTCS=0.1:0.1:0.2
        counter=counter+1;
        tableres=[];
        % offset_CTCS=offset_LECS-;
        offset_LECT=offset_LECS-offset_CTCS;
        for Energy=1.2:0.1:2.5
            Prec.params.Ex.DG0          = Energy;
            Prec.params.CT.DG0          = Prec.params.Ex.DG0 - offset_LECT;
            ECS = Prec.params.CT.DG0-offset_CTCS;
            
            Prec                        = paramsRec.calcall(Prec, tickness); % Update the Recombination Parameters (pass thickness)
            DP=DP.generateDeviceparams(NC,activelayer,mobility,0,0,Prec,ECS,4,Hab_CT_dis,L0_CT_dis,marcusrate,Hab_LE_dis,L0_LE_dis);
            
            %% Run the JV scans here
            Vstart  = 0;
            Vend=Prec.results.Vocrad+0.01;
            DP.Layers{2}.r0=0; %R0 for field dependence is 1 nm
            
            DV2=device(DP);
            DV2.Prec=Prec;
            %     dfplot.ELnpx(DV2.sol_eq)
            
            Gen=1;
            tic
            DV2=device.runsolJsc(DV2,Gen);
            %DV2=device(DP);
            toc
            
            tic
            DV2=device.runsolJV(DV2,Gen,Vstart,Vend);
            toc
            
            
            %% plot JV
            figure(2)
            
            [Jsc,Voc,FF,JJ,VV]=dfplot.JV_new(DV2.sol_JV(end),1);
            PCE=Jsc*Voc*FF;% in %
            kdis_CT=DP.Layers{2}.kdis;kdis_LE=DP.Layers{2}.kdisexc;Bfor=DP.Layers{2}.kfor;
            Jsc_rad=Prec.results.Jscrad;Voc_rad=Prec.results.Vocrad;Dvnr=Prec.results.Dvnr;J0rad=Prec.results.J0rad;J0nrad=Jsc_rad/exp((Voc_rad-Dvnr)/0.026);
            FFrad=max((0:0.01:3).*(Jsc_rad-J0rad.*exp((0:0.01:3)./0.026)))/(Jsc_rad.*Voc_rad);PCErad=FFrad*Jsc_rad*Voc_rad;
            FFnrad=max((0:0.01:3).*(Jsc_rad-J0nrad.*exp((0:0.01:3)./0.026)))/(Jsc_rad.*(Voc_rad-Dvnr));PCEnrad=FFnrad*Jsc_rad*(Voc_rad-Dvnr);
            
            kr_CT=Prec.params.CT.results.krTot;knr_CT=Prec.params.CT.results.knr;
            kr_LE=Prec.params.Ex.results.krTot;knr_LE=Prec.params.Ex.results.knr;
            E_LE=Prec.params.Ex.DG0; E_CT=Prec.params.CT.DG0;
            Nc=NC;N_LE=Prec.params.Excitondesnity*1e-6;N_CT=Prec.params.Excitondesnity*1e-6*Prec.params.RCTE ;
            %tableres=[tableres;table(E_LE,E_CT,ECS,kdis_CT,kdis_LE,Bfor,Jsc_rad,Voc_rad,Dvnr,kr_CT,knr_CT,kr_LE,knr_LE,Jsc,Voc,FF,PCE)];
            tableres=[tableres;table(E_LE,E_CT,ECS,kdis_CT,kdis_LE,Bfor,Jsc_rad,Voc_rad,Dvnr,kr_CT,knr_CT,kr_LE,knr_LE,FFrad,J0rad,PCErad,FFnrad,PCEnrad,Jsc,Voc,FF,PCE)];%,Jsc,Voc,FF,PCE)];
            
        end
        eval(['tableres2_' cases{counter} '_LamiLE_' num2str(Li*1000) '_meV=tableres;']);
    end
end
%%
figure
            Colorlist=[[237 85 101];[248 172 89];[235 198 200];[26 179 148];[22 138 198];[13 58 89];[13 08 89];[3 58 189];[13 98 89];[100 58 189];[130 98 89]]./255;

% subplot(1,2,1)
plot(tableres2_dropCTCS_LamiLE_60_meV.E_LE,tableres2_dropCTCS_LamiLE_60_meV.PCE,'*-','DisplayName','E_L_E=E_C_T L_i_L_E =60 meV','Color',Colorlist(1,:))
hold on
% plot(tableres2_dropLECT_LamiLE_60_meV.E_LE,tableres2_dropLECT_LamiLE_60_meV.PCE,'*-','DisplayName','E_C_T=E_C_S L_i_L_E =60 meV','Color',Colorlist(2,:))
plot(tableres2_middlepoint_LamiLE_60_meV.E_LE,tableres2_middlepoint_LamiLE_60_meV.PCE,'*-','DisplayName','middlepoint L_i_L_E =60 meV','Color',Colorlist(3,:))
plot(tableres2_middlepoint_LamiLE_60_meV.E_LE,tableres2_middlepoint_LamiLE_60_meV.PCErad,'*-','DisplayName','Radiative limit L_i_L_E =60 meV','Color',Colorlist(4,:))
plot(tableres2_middlepoint_LamiLE_60_meV.E_LE,tableres2_middlepoint_LamiLE_60_meV.PCEnrad,'*-','DisplayName','non-Radiative limit L_i_L_E =60 meV','Color',Colorlist(5,:))

legend('show');
xlabel('Free energy of LE state [eV]')
ylabel('PCE [%]')

plot(tableres2_dropCTCS_LamiLE_100_meV.E_LE,tableres2_dropCTCS_LamiLE_100_meV.PCE,'o-','DisplayName','E_L_E=E_C_T L_i_L_E =100 meV','Color',Colorlist(1,:))
hold on
% plot(tableres2_dropLECT_LamiLE_100_meV.E_LE,tableres2_dropLECT_LamiLE_100_meV.PCE,'o-','DisplayName','E_C_T=E_C_S L_i_L_E =100 meV','Color',Colorlist(2,:))
plot(tableres2_middlepoint_LamiLE_100_meV.E_LE,tableres2_middlepoint_LamiLE_100_meV.PCE,'o-','DisplayName',' middlepoint L_i_L_E=100 meV','Color',Colorlist(3,:))
plot(tableres2_middlepoint_LamiLE_100_meV.E_LE,tableres2_middlepoint_LamiLE_100_meV.PCErad,'o-','DisplayName','Radiative limit L_i_L_E =100 meV','Color',Colorlist(4,:))
plot(tableres2_middlepoint_LamiLE_100_meV.E_LE,tableres2_middlepoint_LamiLE_100_meV.PCEnrad,'o-','DisplayName','non-Radiative limitL_i_L_E =100 meV','Color',Colorlist(5,:))


plot(tableres2_dropCTCS_LamiLE_150_meV.E_LE,tableres2_dropCTCS_LamiLE_150_meV.PCE,'s-','DisplayName','E_L_E=E_C_T L_i_L_E =150 meV','Color',Colorlist(1,:))
hold on
% plot(tableres2_dropLECT_LamiLE_100_meV.E_LE,tableres2_dropLECT_LamiLE_100_meV.PCE,'o-','DisplayName','E_C_T=E_C_S L_i_L_E =100 meV','Color',Colorlist(2,:))
plot(tableres2_middlepoint_LamiLE_150_meV.E_LE,tableres2_middlepoint_LamiLE_150_meV.PCE,'s-','DisplayName',' middlepoint L_i_L_E=150 meV','Color',Colorlist(3,:))
plot(tableres2_middlepoint_LamiLE_150_meV.E_LE,tableres2_middlepoint_LamiLE_150_meV.PCErad,'s-','DisplayName','Radiative limit L_i_L_E =150 meV','Color',Colorlist(4,:))
plot(tableres2_middlepoint_LamiLE_150_meV.E_LE,tableres2_middlepoint_LamiLE_150_meV.PCEnrad,'s-','DisplayName','non-Radiative limitL_i_L_E =150 meV','Color',Colorlist(5,:))

legend('show');
xlabel('Free energy of LE state [eV]')
ylabel('Jsc [mA cm-2]')

%%
writetable(tableres2_dropCTCS,'efficiency_limit_dropCTCS_sameNCTNCS2.xls','Sheet',1)
writetable(tableres2_middlepoint,'efficiency_limit_dropCTCS_middlepoint2.xls','Sheet',1)
writetable(tableres2_dropLECT,'efficiency_limit_dropLECT_sameNCTNCS2.xls','Sheet',1)
%%
for Li=[0.06,0.1]%0.15%:0.01:0.1
    Prec.params.Ex.Li           = Li;
    counter=0;
cases={'dropLECT','middlepoint','dropCTCS'};

for offset_CTCS=0:0.1:0.2
counter=counter+1;
tablename=['tableres2_' cases{counter} '_LamiLE_' num2str(Li*1000) '_meV'];
eval([tablename '.Jsc=' tablename '.Jsc.*(' tablename '.Jsc_rad+2)./' tablename '.Jsc_rad;'])
eval([tablename '.Jsc_rad=' tablename '.Jsc_rad+2;'])
eval([tablename '.PCEnrad=' tablename '.Jsc_rad.*' tablename '.FFnrad.*(' tablename '.Voc_rad-' tablename '.Dvnr);'])
eval([tablename '.PCErad=' tablename '.Jsc_rad.*' tablename '.FFrad.*' tablename '.Voc_rad;'])
eval([tablename '.PCE=' tablename '.Jsc.*' tablename '.Voc.*' tablename '.FF;'])

Excel_name=['efficiency_limit_' cases{counter} '_LamiLE_' num2str(Li*1000) '_meV.xls'];
eval(['writetable(' tablename ', Excel_name,''Sheet'',1);'])
end
end