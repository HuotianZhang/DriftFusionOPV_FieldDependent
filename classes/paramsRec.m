classdef paramsRec
    % paramsRec - Recombination parameters for CT and Exciton states
    %
    % IMPORTANT NOTE ON THICKNESS PARAMETER:
    % The thickness parameter is NO LONGER stored in this class.
    % Thickness must be passed as a parameter to calcall() and absorptionSIm().
    % The canonical source of thickness is deviceparams.Layers{}.tp (in cm).
    % See docs/THICKNESS_PARAMETER.md for complete documentation.
    
    properties
        const
        params
        results
    end
    methods (Static)
        function Prec=paramsRec
%             const.V=30;
            % Physical constants (consolidated - CODATA 2018 values)
            const.kb=8.6173324e-5;              % Boltzmann constant [eV K^-1]
            const.me=9.1093837015e-31;          % Electron mass [kg] (CODATA 2018)
            const.h=6.62607015e-34;             % Planck constant [J] (CODATA 2018)
            const.e=1.602176634e-19;            % Elementary charge [C] (CODATA 2018)
            const.T=300;                        % Temperature of the system [K]
            const.Edistribution=0.5:0.005:3;    % Energy distribution for absorption spectra (linearly spaced)
            const.c=2.99792458e8;               % Speed of light in vacuum [m s^-1]
            const.eps0=4*pi*8.8541878128e-12*6.242e+18; % Vacuum permittivity in eV.m-1*4pi
            data = load('spectrum.mat'); % in ./Data
            const.solflux(:,1) = data.E;
            const.solflux(:,2) = data.photonFlux;% photonFlux has units mA/cm^2/eV 
            % phflux = interp1( data.E,photonFlux,Energy);
            % [~,const.solflux] = ShockleyQueisser(1);%used to get the sun spectrum
            const.bb=blackbody(const.T,const.Edistribution);%black body in units mA/cm^2/eV
%             const.chemicalpot=0.9;
            % NOTE: Thickness is no longer stored in paramsRec. 
            % It should be defined only in deviceparams.Layers{}.tp
            %params.sizeofsite=5e-10;%size of the site in m ( need to define it in terms of density of states) 
            params.Excitondesnity=1/power(5e-10,3);% in unit m^-3
			params.nie=1.5;%refrective index of the medium
            params.RCTE=1;%ratio CT to S1
            %% EXciton properties          
            params.Ex.f=5;%oscillator strength of the CT state
            params.Ex.L0=0.1;%outer reorganisation energy(low frequency) in eV
            params.Ex.Li=0.13;%inner reorganisation energy in eV
            params.Ex.DG0=1.55;%energy of the CT state in  eV
            params.Ex.Number_Vibronic_Mode_initial=5;%number of vibronic mode considered for the CT state
            params.Ex.Number_Vibronic_Mode_final=15;%number of vibronic mode considered for the ground state
            params.Ex.hW=0.15;%main vibronic energy considered in eV
            params.Ex.sigma=0.001;%gaussian distribution for CT state
            params.Ex.Dmus=3*3.33e-30/const.e;%difference in static dipole moment (10 in DEbye )
            params.Ex.numbrestate=2;
            %% CT properties
            params.CT.f=0.001;%oscillator strength of the CT state
            params.CT.L0=0.14;%outer reorganisation energy(low frequency) in eV
            params.CT.Li=0.13;%inner reorganisation energy in eV
            params.CT.DG0=1.35;%energy of the CT state in  eV
            params.CT.Number_Vibronic_Mode_initial=5;%number of vibronic mode considered for the CT state
            params.CT.Number_Vibronic_Mode_final=15;%number of vibronic mode considered for the ground state
            params.CT.hW=0.15;%main vibronic energy considered in eV
            params.CT.sigma=0.001;%gaussian distribution for CT state
            params.CT.Dmus=10*3.33e-30/const.e;%difference in static dipole moment (10 in DEbye )
            params.CT.numbrestate=2;
            %%%%%%% add this to account for the effect of Hybredisation
            params.Vstar=0.020; % Coupling between S1 and CT in eV
            Prec.params=params;
            Prec.const=const;
            Prec=paramsRec.update(Prec);

        end
        function params=updatelaguerre(params,const)
            params.funlaguerre=[];

            for m=0:1:params.Number_Vibronic_Mode_final
                for n=0:1:params.Number_Vibronic_Mode_initial

                    params.funlaguerre(m+1,n+1) =  laguerreL(n,(m-n),params.S);
                end
            end
        end 
        function params=updatestate(params,const)
            hbarEV=const.h/const.e/2/pi	;
            
            params.S=params.Li/params.hW;%huang rhys factor
             params.Gausswidth=5* params.sigma;
            params.Statedistribution=linspace(params.DG0-params.Gausswidth,params.DG0+params.Gausswidth, params.numbrestate);%need to be linearly spaced
            params.Znorm=0;
            params.Znormabs=0;
            if params.numbrestate<2
                StateEnergyspacing=1;
            else
            StateEnergyspacing=params.Statedistribution(2)-params.Statedistribution(1);
            end
            try
                if min(size(params.funlaguerre)==[params.Number_Vibronic_Mode_final+1,params.Number_Vibronic_Mode_initial+1])
                    
                else
                    params=paramsRec.updatelaguerre(params,const);
                end
            catch
                params=paramsRec.updatelaguerre(params,const);
                
            end
            for energy=params.Statedistribution
                params.Znorm=params.Znorm+exp(-(energy-params.DG0)^2/2/params.sigma^2)*exp(-(energy)/const.T/const.kb)*StateEnergyspacing;
                params.Znormabs=params.Znormabs+exp(-(energy-params.DG0)^2/2/params.sigma^2)*StateEnergyspacing;
            end
            params.Dmu=sqrt(3/2*const.h*params.f/const.me/(params.DG0-params.hW)*hbarEV/2/pi);
        end
        function Prec=update(Prec)
            params=Prec.params;
            const=Prec.const;
            params.CT=paramsRec.updatestate(params.CT,const);
            params.Ex=paramsRec.updatestate(params.Ex,const);
            %%%
            params.offset=params.Ex.DG0-params.CT.DG0;            
            const.bb=blackbody(const.T,const.Edistribution);
            if params.offset>0
                params.CT.Dmu=params.CT.Dmu+params.Vstar*params.Ex.Dmu/params.offset;
            end
            Prec.params=params;
            Prec.const=const;
        end
        
        function y=FC_em(params,const,E,m,n,laguerrecalc)
            kb=8.6173324e-5;
            T=const.T;
            if (n==0)
                y=exp(-params.S)*power(params.S,m)/factorial(m)*exp(-power(params.DG0-(E+m*params.hW+params.L0),2)/4/abs(params.L0)/kb/T);%*exp(-(n+m)*params.hW/kb/T);
            else
                y=exp(-params.S)*power(params.S,m-n)*(factorial(n)/factorial(m))*power(laguerrecalc(m+1,n+1),2)*exp(-power(params.DG0-(E+(m-n)*params.hW+params.L0),2)/4/abs(params.L0)/kb/T)*exp(-(n)*params.hW/kb/T);
            end
        end
        function y=FC_abs(params,const,E,final,initial,laguerrecalc)
            kb= const.kb;
            T=const.T;
            if (initial==0)
                y=exp(-params.S)*power(params.S,final)/factorial(final)*exp(-power(-params.DG0-(-E+final*params.hW+params.L0),2)/4/abs(params.L0)/kb/T);%*exp(-(n+m)*params.hW/kb/T);
            else
                y=exp(-params.S)*power(params.S,final-initial)*(factorial(initial)/factorial(final))*power(laguerrecalc(final+1,initial+1),2)*exp(-power(-params.DG0-(-E+(final-initial)*params.hW+params.L0),2)/4/abs(params.L0)/kb/T)*exp(-(initial)*params.hW/kb/T);
            end
        end
        function Prec=calcFCWD(Prec)
            Prec.params.CT=paramsRec.FCWD(Prec.params.CT,Prec.const);
            Prec.params.Ex=paramsRec.FCWD(Prec.params.Ex,Prec.const);           
        end
        function params=FCWD(params,const)

            %%%%%%%%%%%%%%%%Laguerre poly%%%%%%%%%%%%%%%%
            
            laguerrecalc=params.funlaguerre;
            %zeros(params.Number_Vibronic_Mode_initial+1,params.Number_Vibronic_Mode_final+1);
%             for m=0:1:params.Number_Vibronic_Mode_final
%                 for n=0:1:params.Number_Vibronic_Mode_initial
%                     laguerrecalc(m+1,n+1)=params.funlaguerre{m+1,n+1}(params.S);
%                 end
%             end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            istate=0;
            
            %%%%%%%%%%%%%%%%FCWD(E)*E^3 for emission and absorption from CT state and Ground state%%%%%%%%%%%%%%%%
            for energy=params.Statedistribution
                istate=istate+1;
                FCWD0(istate)=0;
                wavei=0;
                %%%%%%%%%%%%%%%%% FCWD(0) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                for m=0:1:params.Number_Vibronic_Mode_final
                    for n=0:1:params.Number_Vibronic_Mode_initial
                        params0=params;
                        params0.DG0=energy;
                        FCWD0(istate)=paramsRec.FC_em(params0,const,0,m,n,laguerrecalc)/sqrt(4*pi*params.L0*const.kb*const.T)*exp(-(energy)/(const.kb*const.T))/params.Znorm+ FCWD0(istate);
                        
                    end
                end
                for E=const.Edistribution
                    wavei=wavei+1;
                    FCWDEm(istate,wavei)=0;
                    
                    FCWDabs(istate,wavei)=0;
                    for m=0:1:min(params.Number_Vibronic_Mode_final,params.Number_Vibronic_Mode_initial)
                        for n=0:1:min(params.Number_Vibronic_Mode_final,params.Number_Vibronic_Mode_initial)
                            paramsem=params;
                            paramsem.DG0=energy;
                            FCWDEm(istate,wavei)=FCWDEm(istate,wavei)+paramsRec.FC_em(paramsem,const,E,m,n,laguerrecalc)/sqrt(4*pi*params.L0*const.kb*const.T)*exp(-(energy)/(const.kb*const.T))/params.Znorm;
                            FCWDabs(istate,wavei)=FCWDabs(istate,wavei)+paramsRec.FC_abs(paramsem,const,E,n,m,laguerrecalc)/sqrt(4*pi*params.L0*const.kb*const.T);
                            
                        end
                    end
                end
            end 
            params.results.FCWD0=FCWD0;
            params.results.FCWDEm=FCWDEm;
            params.results.FCWDabs=FCWDabs;
        end
        function Prec=Calcrates(Prec)
            %             Prec=paramsRec.calcFCWD(Prec);
            Prec.params.CT=paramsRec.Calcrate(Prec.params.CT,Prec.const);
            Prec.params.Ex=paramsRec.Calcrate(Prec.params.Ex,Prec.const);
            offset=Prec.params.Ex.DG0-Prec.params.CT.DG0;
            kbT=Prec.const.kb*Prec.const.T;%in eV
            try
                 radiativeDecay     = Prec.params.CT.results.krTot + Prec.params.Ex.results.krTot * exp(-offset / kbT) / Prec.params.RCTE;
                 nonRadiativeDecay  = Prec.params.CT.results.knr   + Prec.params.Ex.results.knr   * exp(-offset / kbT) / Prec.params.RCTE;                
                 Prec.results.Qi    = radiativeDecay / (radiativeDecay + nonRadiativeDecay);
                 Prec.results.Qe    = 1 / ((1 + (Prec.results.pe - 1) * Prec.results.Qi) / Prec.results.pe / Prec.results.Qi);
                 Prec.results.Dvnr  = Prec.const.kb*Prec.const.T*(log((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi));
            catch 
                disp("get the pe first")
                
            end 
%             end
        end
        function params=Calcrate(params,const)
            
            hbarEV=const.h/const.e/2/pi	;
            kth=1e14;
            
            %%%%%%%%%%%%% calculate the rates
            if params.numbrestate<2
                StateEnergyspacing=1;
            else
                StateEnergyspacing=params.Statedistribution(2)-params.Statedistribution(1);
            end
            wavespacing=const.Edistribution(2)-const.Edistribution(1);
            results.Hab=params.Dmu*(params.DG0)/sqrt(power(params.Dmus,2)+4*power(params.Dmu,2));
            istate=0;
            knr=0;
            for energy=params.Statedistribution
                istate=istate+1;
                knr=knr+params.results.FCWD0(istate)*2*pi/hbarEV*results.Hab^2*StateEnergyspacing*exp(-(energy-params.DG0)^2/2/params.sigma^2);
            end
            kr=0;
            wavei=0;
            for E=const.Edistribution
                wavei=wavei+1;
                krE(wavei)=0;
                istate=0;
                for energy=params.Statedistribution
                    istate=istate+1;
                    krE(wavei)=krE(wavei)+4/3/hbarEV*params.results.FCWDEm(istate,wavei)*(power(params.Dmu,2))/const.eps0/power(const.c*hbarEV/E,3)*StateEnergyspacing*exp(-(energy-params.DG0)^2/2/params.sigma^2);
                end
                kr=kr+krE(wavei)*wavespacing;
            end
            
            params.results.knr=knr*kth/(knr+kth);
            params.results.Hab=params.Dmu*(params.DG0)/sqrt(power(params.Dmus,2)+4*power(params.Dmu,2));
            params.results.krTot=kr;
            params.results.krE=krE;
            
            
        end
        function params=absorptionstate(params,const)
            %%%%%%%%%%%%%%%%%%%absorption spectrum%%%%%%%%%%%%%%%%%
            hbarEV=const.h/const.e/2/pi	;
            if params.numbrestate<2
                StateEnergyspacing=1;
            else
                StateEnergyspacing=params.Statedistribution(2)-params.Statedistribution(1);
            end
            Einterp=const.Edistribution;
            wavei=0;
            %%%%%%%%%%%%%%Absorption coeff
            for E=Einterp
                wavei=wavei+1;             
                alphaLJ(wavei)=0;                         
                istate=0;
                for energy=params.Statedistribution
                    istate=istate+1;
                    alphaLJ(wavei)=alphaLJ(wavei)+params.results.FCWDabs(istate,wavei)*(power(params.Dmu,2))...
                        /const.c/hbarEV/6/const.eps0*E...
                        *StateEnergyspacing*exp(-(energy-params.DG0)^2/2/params.sigma^2)*1/params.Znormabs;
                    %*params.nie/power(params.sizeofsite,3)               
                end

            end
            %%%%%%%%%%%%%absorption
            params.results.alphaLJ=alphaLJ;
        end
        function Prec=absorptionSIm(Prec, tickness)
            % absorptionSIm - Calculate absorption spectrum and radiative properties
            %
            % Inputs:
            %   Prec     - paramsRec object with CT and Ex parameters
            %   tickness - Device thickness in meters (m)
            %
            % Note: Thickness must be provided as parameter. It is no longer
            % stored in Prec.params.tickness. The canonical source is 
            % deviceparams.Layers{}.tp (in cm).
            
            %%%%%%%%%%%%%%%%%%%absorption spectrum%%%%%%%%%%%%%%%%%
            Prec.params.CT = paramsRec.absorptionstate(Prec.params.CT, Prec.const);
            Prec.params.Ex = paramsRec.absorptionstate(Prec.params.Ex, Prec.const);
            Einterp = Prec.const.Edistribution;
            bbinterp = interp1(Prec.const.bb(:,1),Prec.const.bb(:,2),Einterp);
                        

            wavei=0;
            wavei0=0;
            %%%%%%%%%%%%%%Absorption coeff in m-1
            for E=Einterp
                wavei=wavei+1;
                
                alphaLJ(wavei)=0;
                
                if(E>Prec.params.Ex.DG0+Prec.params.Ex.L0)
                    if wavei0==0
                        wavei0=wavei;
                        E0=E;
                    end
                    alphaLJ(wavei)=(Prec.params.Ex.results.alphaLJ(wavei0)+Prec.params.RCTE*Prec.params.CT.results.alphaLJ(wavei0))...
                        *Prec.params.nie*Prec.params.Excitondesnity*sqrt((E-Prec.params.Ex.DG0)/Prec.const.kb/Prec.const.T)/sqrt((E0-Prec.params.Ex.DG0)/Prec.const.kb/Prec.const.T);
                else
                    alphaLJ(wavei)=(Prec.params.Ex.results.alphaLJ(wavei)+Prec.params.RCTE*Prec.params.CT.results.alphaLJ(wavei))...
                        *Prec.params.nie*Prec.params.Excitondesnity;                       
                end
            end
            %%%%%%%%%%%%%absorption
            int=1;
            for E=Einterp
                AbsLJ(int) = 1-exp(-2*tickness*alphaLJ(int));
                int=int+1;
            end
            %%%%%%%%%%%%JSC rad%%%%%%%%%%%%%%%%%%%%%%
            
            solarphlux           = interp1(Prec.const.solflux(:,1),Prec.const.solflux(:,2),Einterp);
            Jscrad               = trapz(Einterp, AbsLJ   .* solarphlux);
            J0rad                = trapz(Einterp, AbsLJ   .* bbinterp);
            integralRadRec       = trapz(Einterp, alphaLJ .* bbinterp * 4 * tickness * Prec.params.nie^2);
            radiativeEmission    = alphaLJ .* bbinterp * 4 * Prec.params.nie^2 * 1e-2;
            Prec.results.R0rad   = trapz(Einterp, radiativeEmission);% here R0rad is in cm-3%Epsilon,out isconsidered ot be equal to pi according to equation 23 in 10.1103/PhysRevB.90.035211  %radiative emission rate based on black body radiation
            Prec.results.Jscrad  = Jscrad;
            Prec.results.AbsLJ   = AbsLJ;
            Prec.results.alphaLJ = alphaLJ;
            Prec.results.pe      = J0rad / integralRadRec;
            Prec.results.J0rad   = J0rad;
            Prec.results.Vocrad  = Prec.const.kb*Prec.const.T*(log(Prec.results.Jscrad/Prec.results.J0rad+1));
            % semilogy(results.Einterp,results.AbsLJ)
            
        end
        function Prec=calcall(Prec, tickness)
            % calcall - Calculate all recombination parameters
            %
            % Inputs:
            %   Prec     - paramsRec object
            %   tickness - Device thickness in meters (m)
            %
            % Note: Thickness must be provided as parameter. It is no longer
            % stored in Prec.params.tickness. The canonical source is 
            % deviceparams.Layers{}.tp (in cm), which should be converted
            % to meters before calling this function.
            
            Prec = paramsRec.update(Prec);
            Prec = paramsRec.calcFCWD(Prec);
            Prec = paramsRec.absorptionSIm(Prec, tickness);
            Prec = paramsRec.Calcrates(Prec);

        end
    end
end