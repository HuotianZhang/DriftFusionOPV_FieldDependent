count=0;
Templist=290:10:350;
Thickness_list=70:20:300;
mobility_list_activation=0:0.1:0.5;%logspace(-5.5,-4.5,10);
Kfor_list_activation=0:0.1:0.5;%logspace(-11,-9,10);
    Prec=paramsRec;%first initiliase the recombination parameters ( the parameters are set here by default and can be changed under or in the paramRec function
temp=Templist(1);%:10:350
AL_thickness=Thickness_list(1);
mobility=2e-4*exp(-mobility_list_activation(1)/temp/Prec.const.kb)/exp(-mobility_list_activation(1)/300/Prec.const.kb);
Kfor=1e-11*exp(-Kfor_list_activation(1)/temp/Prec.const.kb)/exp(-Kfor_list_activation(1)/300/Prec.const.kb);

    devicename="_"+num2str(AL_thickness)+"nm_"+num2str(temp)+"K_"+num2str(mobility,'%1.0e')+"mAVs_"+num2str(Kfor,'%1.0e')+"cm3s1";
  %%  
    AL_thickness=AL_thickness*1e-7;
    %% First Calculate the Recombination paramters of the CT and Exciton
    %here we also calculate the absorption profile of the device and the
    %emission spectra based on the properties of the states,
    %below are a set of parameters that can be changed
    Prec.params.Ex.DG0=1.63;
    Prec.params.CT.f=5e-4;
    offset=0.37;
    tickness=AL_thickness*1e-2;%in m
    Prec.params.CT.DG0=Prec.params.Ex.DG0-offset;
    Prec.params.RCTE=0.5;
    Prec.params.Ex.Li=0.15;
    Prec.params.CT.Li=0.15;
    Prec.params.CT.L0=0.18;
    Prec.params.Ex.f=5;
    Prec.params.Vstar=0.001;
    Prec.const.T=temp;
    Prec=paramsRec.calcall(Prec, tickness);%this line calculated the different properties of the states (pass thickness)
    krecCT=Prec.params.CT.results.knr;krecex=Prec.params.Ex.results.knr;
    Voc=Prec.results.Vocrad-Prec.results.Dvnr;
    %% in this part we generate a device with a certain number of properties
    %the default properties are set in pnParamsHCT or in the excel file p3hTPCBM.xlsx
    
    NC=2e19;activelayer=2;Kfor=1e-11;%V in V, K in S-1, NC in Cm-3, Jsc in mA cm-2,
    mobility=3e-4;kdis=5e10;kdisex=1e11;% Tq1 in s,mobility in Cm2V-1s-1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DP=pnParamsHCT;
    
    DP.light_properties.OM=2;%to consider the transfer matrix generation profile
    DP.Time_properties.tpoints=100;
    DP.Layers{activelayer}.tp=AL_thickness;
    DP=DP.generateDeviceparams(NC,activelayer,mobility,kdis,kdisex,Prec,1e-11,0);
    clear NC activelayer kdis kdisex
    %% Run the JV scans here
    Vstart=0;Vend=1.5;
    tic
    DP.Layers{2}.r0=0; %R0 for field dependence is 1 nm
    
    DV2=device(DP);
    DV2.Prec=Prec;
    toc
    %%
    suns=[0.01,0.05,0.1,0.5,1];
    countsuns=0;
    for Gen=suns
        count=count+1;
        countsuns=countsuns+1;
        tic
        DV2=device.runsolJsc(DV2,Gen);
        toc
        
        tic
        DV2=device.runsolJV(DV2,Gen,Vstart,Vend);
        toc

        [Jsc,Voc,FF,JJ,VV]=dfplot.JV_new(DV2.sol_JV(countsuns),0);
        tableres(count).Voc=Voc;
        tableres(count).JJ=JJ;
        tableres(count).VV=VV;
        tableres(count).FF=FF;
        tableres(count).Jsc=Jsc;
        tableres(count).Gen=Gen;
        tableres(count).mobility=mobility;
        tableres(count).AL_thickness=AL_thickness*1e7;
        tableres(count).temp=temp;
        tableres(count).Kfor=Kfor;
    end
save("results"+devicename+".mat",'tableres');
    