%Marco Antonio Pacheco Quintero   213535019
%Procesamiento digital de senales
%Implementacion de vision robotica

clear all; close all; clc;

% Configurar arduino
a = arduino('COM3', 'Uno');
% Posicion inicial servos
Pan = 0.5;
Tilt = 0.5;
% Configurar servos
sPan = servo(a, 'D4', 'MinPulseDuration', 700*10^-6, 'MaxPulseDuration', 2300*10^-6);
writePosition(sPan, Pan);
sTilt = servo(a, 'D7', 'MinPulseDuration', 700*10^-6, 'MaxPulseDuration', 2300*10^-6);
writePosition(sTilt, Tilt);
% KPan = 0.00005;
% KTilt = -0.00040;
%Ganancias del controlador
KPan = 0.00027;
KTilt = -0.000405;
% Inicializamos camara
camList = webcamlist;
cam = webcam(1);

%Tomamos captura para seleccion
X = snapshot(cam);
X = X(1:2:end,1:2:end,:);
X = im2double(X);
figure(1);
imshow(X);

seleccion = roipoly;   %Seleccion de objeto

SelR = X(:,:,1).*seleccion;
SelG = X(:,:,2).*seleccion;
SelB = X(:,:,3).*seleccion;

%Obtenemos el promedio de lo seleccionado
R = sum(SelR(:))/sum(seleccion(:));
G = sum(SelG(:))/sum(seleccion(:));
B = sum(SelB(:))/sum(seleccion(:));
drawnow 

Pixel = 40/256;
Xe = zeros(1,500);
Ye = zeros(1,500);
for idx=1:500
    
X = snapshot(cam);
%X = imrotate(X,-180);
%X = X(1:2:end,1:2:end,:);
X = X(1:2:end,1:2:end,:);
X = im2double(X);

%Filtrado de Imagen

%A�adimos ruido a la imagen
[m,n,o] = size(X);
X = X + 0.5*rand(m,n,o);
    %Transformada de fourier
Xf = fftshift(fft2(X));
    %Creamos Filtro
a = m/2;
b = n/2;
r = 20;
H = 0*X;

for im = 1:m
    for in = 1:n
        for io = 1:o
            if (im-a)^2 + (in-b)^2 < r^2
                H(im,in,io) = 1;
            end
        end
    end
end
    %Aplicamos filtro
Yf = Xf.*H;
    %Volvemos a imagen original
X = abs(ifft2(ifftshift(Yf)));

%Segmentacion del color
CapaR = X(:,:,1)>R-Pixel & X(:,:,1)<R+Pixel;
CapaG = X(:,:,2)>G-Pixel & X(:,:,2)<G+Pixel;
CapaB = X(:,:,3)>B-Pixel & X(:,:,3)<B+Pixel;

BusqColor = CapaR.*CapaG.*CapaB;
[XColor, YColor]=find(BusqColor==1);
CX = sum(XColor(:))/sum(BusqColor(:));
CY = sum(YColor(:))/sum(BusqColor(:));

figure(2);
imshow(BusqColor);            %Graficamos segmentacion y centroide
hold on;
plot(CY,CX,'om','linewidth', 6);

X_error = b - CY; %Error Horizontal
Y_error = a - CX; %Erro Vertical
Xe(idx) = X_error;
Ye(idx) = Y_error;
if(((X_error>25)||(X_error<-25)) && ((Y_error>25)||(Y_error<-25)))

% Calculando nueva posicion 
Pan = Pan + KPan*X_error;
Tilt = Tilt + KTilt*Y_error;

% Limites para asegurar posicon entre 0 y 1
Pan = min(0.99, max(0.01, Pan));
Tilt = min(0.99, max(0.01, Tilt));

% Enviamos la nueva posicion a los servos
writePosition(sPan, Pan);
writePosition(sTilt, Tilt);

pause(0.01);
end

drawnow 
end