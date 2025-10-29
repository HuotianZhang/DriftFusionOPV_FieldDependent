%% first set the parameters for the recombination model

%Prec                        = DV_D4A2_CTdissfielddependent.Prec;
Prec=paramsRec;% initiliase the recombination parameters (default values)
% fixed model parameters for the efficiency limit exploration
tickness                    = 100 * 1e-9;
Prec.params.Ex.sigma        = 0.0001;Prec.params.CT.sigma        = 0.0001;
Prec.params.Ex.numbrestate  = 1;Prec.params.CT.numbrestate  = 1;
Prec.const.Edistribution=0.5:0.005:4;%the energy distribution for the absorption spectra%need to be linearly spaced
  Prec.params.Ex.Number_Vibronic_Mode_initial=5;   Prec.params.Ex.Number_Vibronic_Mode_final=15;%number of vibronic mode considered for the ground state
  Prec.params.CT.Number_Vibronic_Mode_initial=5;  Prec. params.CT.Number_Vibronic_Mode_final=15;%number of vibronic mode considered for the ground state
Prec.params.Excitondesnity  = 8e27; %in m-3
%energetics that will be changed along the exploration of the highest
%efficiency
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
NC          = 2e19;    %set to the same degeneracy as the CT state
mobility    = 3e-3;%DV_D4A2_CTdissfielddependent.DP.Layers{2}.mue;     % Charge Carrier Mobility           % cm^2 / V / s
kdis=1e10;%DV_D4A2_CTdissfielddependent.DP.Layers{2}.kdis*0.1;
kdisex=1e10;%DV_D4A2_CTdissfielddependent.DP.Layers{2}.kdisexc*0.1;
kfor=1e-11;%DV_D4A2_CTdissfielddependent.DP.Layers{2}.kfor;
DP=DP.generateDeviceparams(NC,activelayer,mobility,kdis,kdisex,Prec,kfor,0);


    %% 0D model
    %     kforr=DP.Layers{2}.kfor;
    fignumber=1;
    DP.simulate_PL(Prec,fignumber);
    DP.simulate_EL(Prec,fignumber);
    %DP.simulateTAS(2e10,1e27,fignumber);
    figure(fignumber)
    subplot(2,2,1)
    semilogy(Prec.const.Edistribution,Prec.results.AbsLJ)
    xlabel('Energy [eV]')
    ylabel('EQE [a.u]')
    ylim([1*1e-7, 1])
    xlim([1,2])
    sgtitle(['Vocrad= ' num2str(DP.results.Vocrad) ' DVnr= ' num2str(DP.results.DVnr) ' Voc= ' num2str(DP.results.Voc)])
    %             legend("ToT","From CT","FromEx")
    pause(0.1)
    %% Run the JV scans here
    Vstart=0;Vend=1.5;
    counter=20;
    mobility    = 1e-4;%DV_D4A2_CTdissfielddependent.DP.Layers{2}.mue;
    kdis=1e11;%DV_D4A2_CTdissfielddependent.DP.Layers{2}.kdis*0.1;

    DP=DP.generateDeviceparams(NC,activelayer,mobility,kdis,kdisex,Prec,kfor,0);
    DP.Layers{1}.muee=1e-3;
    DP.Layers{3}.mupp=1e-3;
    DP.Layers{1}.tp=1e-5;
    DP.Layers{3}.tp=1e-5;
        DP.External_prop.Rseries=0;
    DP.Experiment_prop.BC =3;
    Prec=paramsRec.calcall(Prec, tickness);%this line calculated the different properties of the states.

    sn=1e20;
    DP.External_prop.sn_l=sn;%left Electron extraction/surface recombination coefficient in cm s^-1
    DP.External_prop.sn_r=sn;%right Electron extraction/surface recombination coefficient in cm s^-1
    DP.External_prop.sp_l=sn;%left hole extraction/surface recombination coefficient in cm s^-1
    DP.External_prop.sp_r=sn;%right hole extraction/surface recombination coefficient in cm s^-1
    tic
    
    DP.Layers{2}.r0_CT=0;%3e-7; %R0 for field dependence is 1 nm (typical values 1e-7 cm)
    DP.Layers{2}.r0_Ex=0;%R0 for field dependence is 1 nm (typical values 1e-7 cm) 
    DV2=device(DP);
    DV2.Prec=Prec;
    toc
    %
    suns=1;%[0.01,0.05,0.1,0.5,1];
    for Gen=suns
        tic
        DV2=device.runsolJsc(DV2,Gen);
        toc
        
        tic
        DV2=device.runsolJV(DV2,Gen,Vstart,Vend);
        toc
%         tic
%         DV2=device.runsolJV(DV2,Gen,Vstart,-5);
%         toc
    end
    assignin('base',"DV_D4A2_nofield"+num2str(counter),DV2)
    %%
     close all
    figure(4)

    %[Jsc,Voc4,FF]=dfplot.JV_new(DV_D4A2_nofield6.sol_JV(1),1);
    %[Jsc,Voc4,FF]=dfplot.JV_new(DV_D4A2_nofield8.sol_JV(1),1);
    %[Jsc,Voc5,FF]=dfplot.JV_new(DV_D4A2_nofield10.sol_JV(1),1);
    %[Jsc,Voc1,FF]=dfplot.JV_new(DV_D4A2_nofield8.sol_JV(1),1);
    %[Jsc,Voc2,FF]=dfplot.JV_new(DV_D4A2_nofield11.sol_JV(1),1);
    %[Jsc,Voc3,FF]=dfplot.JV_new(DV_D4A2_nofield12.sol_JV(1),1);
    [Jsc,Voc4,FF]=dfplot.JV_new(DV_D4A2_nofield13.sol_JV(1),1);
%     [Jsc,Voc5,FF]=dfplot.JV_new(DV_D4A2_nofield14.sol_JV(1),1);
%     [Jsc,Voc6,FF]=dfplot.JV_new(DV_D4A2_nofield15.sol_JV(1),1);
    [Jsc,Voc7,FF]=dfplot.JV_new(DV_D4A2_nofield16.sol_JV(1),1);
    [Jsc,Voc7,FF]=dfplot.JV_new(DV_D4A2_nofield17.sol_JV(1),1);
    [Jsc,Voc7,FF]=dfplot.JV_new(DV_D4A2_nofield18.sol_JV(1),1);
        [Jsc,Voc7,FF]=dfplot.JV_new(DV_D4A2_nofield19.sol_JV(1),1);
        [Jsc,Voc7,FF]=dfplot.JV_new(DV_D4A2_nofield20.sol_JV(1),1);

%     [Jsc,Voc7,FF]=dfplot.JV_new(DV_D4A2_nofield19.sol_JV(1),1);

    legend
       % [Jsc,Voc,FF]=dfplot.JV_new(DV_D4A2_nofield3.sol_JV(1),1);

    %dfplot.JV_new(DV2.sol_JV(2),1);
    
    %%
        suns=1;%[0.01,0.05,0.1,0.5,1];

    figure(3)
      counter=0;
    for Gen=suns
        counter=counter+1;
        [tableres.Jsc(counter),tableres.Voc(counter),tableres.FF(counter)]=dfplot.JV_new(DV2.sol_JV(2*(counter-1)+1),1);
    end
    tableres.Jsc=tableres.Jsc';
    tableres.Voc=tableres.Voc';
    tableres.FF=tableres.FF';
    tableres.suns=suns';
    tableres=struct2table(tableres);
    %%
    figure(4)
    loglog(tableres.suns,tableres.suns*max(tableres.Jsc))
    hold on
    loglog(tableres.suns,tableres.Jsc,'*')
    %%
    [Jsc,Voc,FF]=dfplot.JV_new(DV2.sol_JV(2),1);
    figure(3)
    dfplot.photoluminescence_mult(DV2,2,0,1," K");
    figure(4)
    dfplot.Electroluminescence_multi(DV2,2,0,2," K")

