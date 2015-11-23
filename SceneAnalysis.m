clear all; close all; clc;

% Natural constants:
r2d = 180/pi;
d2r=pi/180;
h=6.6263*10^(-34); %Planck's constant
c=3*10^8; %Velocity if light
k=1.38062*10^(-23); %Boltzmann's constant
kbis=8.62*10^(-5); %Boltzmann's constant in eV/K

AtargetMin=0.1; % surface's target min [m2]
AtargetMax=1; % surface's target max [m2]
shutterTime=100*10^(-3); % shutter time [s]

lambda=[400 500 600 700 800]*10^(-9); % [400,800] nm (used for plotting)
lambdaSun=[400:0.1:800]*10^(-9); % [400,800] nm

% CCD sensor
pixelSize = 12*10^(-6); % [m]
imageSectionHeight = 12.288*10^(-3); % m
CCDqe=[0.09 0.28 0.22 0.135 0.075]; % wavelengths = [400 500 600 700] nm

% Lens system
alphaLens=0.98; %Pass ban efficiency of lens systm
r=2; %[1,2]
objectSize = 2; % m
FOVr = atan(objectSize/2/r);
FOVd = FOVr*r2d;
EFL = imageSectionHeight/2/tan(FOVr); % m

% Confusion
rf = 1;
f = 1/(1/rf+1/EFL);
Dsrtmp=[1:0.1:5]*10^(-3);
figure; grid on
%h1 = axes; set(h1,'FontSize',14)
DoCrange=Dsrtmp*abs(r-rf)/r*f/(rf-f); % Diameter of Confusion
plot(Dsrtmp, DoCrange,'LineWidth',1.5);

Difspot = zeros(4,length(Dsrtmp));
hold on, grid on
for i=1:4
    Difspot(i,:) = 2*EFL*tan(1.22*lambda(i)./Dsrtmp); % Diffraction spot size on CCD
    plot(Dsrtmp, Difspot(i,:),'LineWidth',1.5);
end
plot(Dsrtmp, 12*10^(-6)*ones(1,length(Dsrtmp)),'LineWidth',1.5)
l = legend('DoC (m)', 'Difspot (m) lambda = 400 nm', 'Difspot (m) lambda = 500 nm', 'Difspot (m) lambda = 600 nm', 'Difspot (m) lambda = 700 nm', 'Pixel Size (m)');
set(l,'FontSize',14)
xlabel('Dsr (m)','FontSize',14)
ylabel('DoC and Difspot (m)','FontSize',14)

Dsr = 0.0019 ; % Effective lens entrance aperture (m)
[i,j] = find(Dsrtmp==Dsr); % indices where we find the value of Dsr in Dsrtmp
DoC = DoCrange(j);
fNumber = f/Dsr; % Aperture

% % Depth of Field
% imageDiagonal = 17.38*10^(-3); % m
% c = imageDiagonal/1000; % diameter of the circle of confusion (m)
m = EFL/rf; % magnification
coc = DoC*m;
H = f^2/(fNumber*coc); % Hyperfocal distance (m)
Dn = H*rf/(H+(rf-f)); % near limit of DoF (m)
Df = H*rf/(H-(rf-f)); % far limit of DoF (m)
DoF = Df - Dn;
DoFbis = 2*f/Dsr*coc*(m+1)/(m^2-(coc/Dsr)^2);

%%
% Reflectance map
IrradianceSun = 530;
Latitude = 50; %latitude in degrees

obliquity = 0;%25.19; ???????????
%at solar noon
angleSunMax = 90-abs(Latitude+obliquity);
IrradianceSunMax=IrradianceSun*sin(angleSunMax*d2r);
%at min work hour
angleSunMin = 10; %arbitrary
IrradianceSunMin=IrradianceSun*sin(angleSunMin*d2r);

%Target properties
alphaMin=0.05; %albedo min
alphaMax=0.45; %albedo max

thetaMin=10; %angle between sun's beam and tagert's normal
thetaMax=50;

%BRDF : Lambertian in min case and 1/10 Glossy and 9/10 Lambertian in max
%case. angle = 0 for glossy bc max case.
RadianceTargetMin = IrradianceSunMin*alphaMin/pi*cos(thetaMin*d2r); % []
RadianceTargetMax = IrradianceSunMax*alphaMax*(1/10+cos(thetaMin*d2r)*(9/(10*pi)));

%Let's assume the target is right in front of the camera
alphaCT = 0; %theta Camera-Target

IrradianceTargetMin=RadianceTargetMin*(pi/4)*(Dsr/EFL)^2*cos(alphaCT*d2r)^4;
IrradianceTargetMax=RadianceTargetMax*(pi/4)*(Dsr/EFL)^2*cos(alphaCT*d2r)^4;

LuminousPowerTowardCamMin = IrradianceTargetMin*AtargetMin; %[W]
LuminousPowerTowardCamMax = IrradianceTargetMax*AtargetMax; %[W]

%% LED
waveLengthLED=520*10^(-9); %[m]
thetaLed = 10;
WLed = 20*10^(-3); % [W]
WLedTCMin = WLed*alphaMin/pi*cos(thetaLed*d2r); % [W]
WLedTCMax = WLed*alphaMax*(1/10+cos(thetaLed*d2r)*(9/(10*pi)));
LuminousPowerLedTCMin = WLedTCMin*(pi/4)*(Dsr/EFL)^2*cos(alphaCT*d2r)^4; % [W]
LuminousPowerLedTCMax = WLedTCMax*(pi/4)*(Dsr/EFL)^2*cos(alphaCT*d2r)^4;

%photons
nPhotonLEDMin = LuminousPowerLedTCMin*shutterTime/(h*c/waveLengthLED);
nPhotonLEDMax = LuminousPowerLedTCMax*shutterTime/(h*c/waveLengthLED);

nphotnoiseLedMin=(pi*(Dsr/2)^2)/(2*pi*r^2)*nPhotonLEDMin;
nphotnoiseLedMax=(pi*(Dsr/2)^2)/(2*pi*r^2)*nPhotonLEDMax;

nenLedMin=nphotnoiseLedMin*28*alphaLens;
nenLedMax=nphotnoiseLedMax*28*alphaLens;



%%
%readOut Noise
NreadOut = 25; %[e-] readout noise

%Dark Current Noise
%bandgapEnergy
T=20+173; %[K]
Ndc0=30; %[pA/cm2]
Ndc0=Ndc0*10^(-3); %[nA/cm2]
Eg=1.1557-7.021*10^(-4)*T^2/(1108+T);
%NdarkCurrent = 100*10^6*shutterTime;
NdarkCurrentPerPix = (2.55*10^(15)*Ndc0*shutterTime*(pixelSize*10^(2))^2*T^(3/2)*exp(-Eg/(2*kbis*T)))^(1/2);
NdarkCurrent=NdarkCurrentPerPix*1024*1024;

%SUN NOISE
%Noise photons per shutter time
noiseMinFun = @(x) LuminousPowerTowardCamMin*shutterTime./(h*c./x); %[] x = lambda
noiseMaxFun = @(x) LuminousPowerTowardCamMax*shutterTime./(h*c./x); %[]

noiseMin=integral(noiseMinFun, 400*10^(-9), 800*10^(-9))/(400*10^(-9));
noiseMax=integral(noiseMaxFun, 400*10^(-9), 800*10^(-9))/(400*10^(-9));


%number of noise photons to Lens
nphotnoiseCCDMin=(pi*(Dsr/2)^2)/(2*pi*r^2)*noiseMin;
nphotnoiseCCDMax=(pi*(Dsr/2)^2)/(2*pi*r^2)*noiseMax;

%Number of noise electrons registered by CCD
nenCCDMin=sum(nphotnoiseCCDMin.*CCDqe*alphaLens)/length(CCDqe);
nenCCDMax=sum(nphotnoiseCCDMax.*CCDqe*alphaLens)/length(CCDqe);
%END SUN NOISE

%% Sun Light without Laser
Noise=sqrt(NreadOut^2+NdarkCurrent^2);
SNRmin=nenCCDMin/Noise;
SNRmax=nenCCDMax/Noise;


%% Sun Light with Laser



