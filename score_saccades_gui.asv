function varargout = score_saccades_gui(varargin)
% SCORE_SACCADES_GUI MATLAB code for score_saccades_gui.fig
%      SCORE_SACCADES_GUI, by itself, creates a new SCORE_SACCADES_GUI or raises the existing
%      singleton*.
%
%      H = SCORE_SACCADES_GUI returns the handle to a new SCORE_SACCADES_GUI or the handle to
%      the existing singleton*.
%
%      SCORE_SACCADES_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SCORE_SACCADES_GUI.M with the given input arguments.
%
%      SCORE_SACCADES_GUI('Property','Value',...) creates a new SCORE_SACCADES_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before score_saccades_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to score_saccades_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help score_saccades_gui

% Last Modified by GUIDE v2.5 05-Jan-2015 14:36:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @score_saccades_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @score_saccades_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before score_saccades_gui is made visible.
function score_saccades_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to score_saccades_gui (see VARARGIN)

% Choose default command line output for score_saccades_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes score_saccades_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = score_saccades_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in epochSearch_listbox.
function epochSearch_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to epochSearch_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns epochSearch_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from epochSearch_listbox
datastruct = guidata(gcbo);
contents = cellstr(get(hObject,'String'));
selectedVal = get(hObject,'value');
datastruct.epochParams = contents{selectedVal};
guidata(gcbo,datastruct) 

% --- Executes during object creation, after setting all properties.
function epochSearch_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochSearch_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

datastruct = guidata(gcbo);
contents = cellstr(get(hObject,'String'));
selectedVal = get(hObject,'value');
datastruct.epochParams = contents{selectedVal};
guidata(gcbo,datastruct) 


% --- Executes on button press in newSMR_pushbutton.
function newSMR_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to newSMR_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

datastruct = guidata(gcbo);

[eyeFile,eyeDir] = uigetfile('*.smr','pick the spike file that has the eyedata for the movies (.smr) ');   %have the user pick the appropriate spike file with the eye data

smrFullPath = fullfile(eyeDir, eyeFile);

if exist(smrFullPath, 'file')
    
    smrParams.path = smrFullPath;
    smrParams.dir = eyeDir;
    smrParams.fname = eyeFile;
    set(handles.smrFile_text,'String',eyeFile)
    
    datastruct.smrParams = smrParams;
    
    guidata(gcbo,datastruct) 
else
    warndlg('Selected File does not exist!','SMR file error!');
end

% --- Executes on button press in newItemFile_pushbutton.
function newItemFile_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to newItemFile_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

datastruct = guidata(gcbo);

[itmFile,itmDir] = uigetfile('*.txt','pick the text item file (e.g. monkey_movies.txt) '); 

itemFullPath = fullfile(itmDir, itmFile);

if exist(itemFullPath, 'file')
    
    itemParams.path = itemFullPath;
    itemParams.dir = itmDir;
    itemParams.fname = itmFile;
    set(handles.itemFile_text,'String',itmFile)
    
    datastruct.itemParams = itemParams;
    
    guidata(gcbo,datastruct) 
else
    warndlg('Selected File does not exist!','Item file error!');
end


% --- Executes on button press in runFile_pushbutton.
function runFile_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to runFile_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

datastruct = guidata(gcbo);
datastruct
if isfield(datastruct, 'itemParams') && isfield(datastruct, 'smrParams')
    
    if ~isfield(datastruct, 'epochParams')
        
    end
    datastruct = runFile_main(datastruct);
    
    guidata(gcbo,datastruct) 
else
    warndlg('Please select item and .SMR files!','Run file error!');
end

% --- Runs a data file and item file 
function outData = runFile_main(inData)

epoch = inData.epochParams;

switch epoch
    case 'All'
        outData = runFile_all(inData)
    case 'Images'
        
    case 'Movies'
        
    otherwise
        warndlg('Please select an epoch!','Epoch selection error!');
end

% --- Loads all data
function outData = runFile_all(inData)

if inData. 

function startTime_edit_Callback(hObject, eventdata, handles)
% hObject    handle to startTime_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startTime_edit as text
%        str2double(get(hObject,'String')) returns contents of startTime_edit as a double

input = get(hObject,'String');

[num, status] = str2num(input);

if status

    datastruct = guidata(gcbo);

    datastruct.timeParams.start = num;

    guidata(gcbo,datastruct) 
    
    fprintf('Start time set to %d.\n', num);
else
    warndlg('Please enter a valid number','Start time error!');
end

% --- Executes during object creation, after setting all properties.
function startTime_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startTime_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

datastruct = guidata(gcbo);

datastruct.timeParams.start = 0;

guidata(gcbo,datastruct) 


function stopTime_edit_Callback(hObject, eventdata, handles)
% hObject    handle to stopTime_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stopTime_edit as text
%        str2double(get(hObject,'String')) returns contents of stopTime_edit as a double
input = get(hObject,'String');

[num, status] = str2num(input);

if status

    datastruct = guidata(gcbo);

    datastruct.timeParams.stop = num;

    guidata(gcbo,datastruct) 
    
    fprintf('Stop time set to %d.\n', num);
else
    warndlg('Please enter a valid number','Stop time error!');
end

% --- Executes during object creation, after setting all properties.
function stopTime_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopTime_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

datastruct = guidata(gcbo);

datastruct.timeParams.stop = 0;

guidata(gcbo,datastruct) 