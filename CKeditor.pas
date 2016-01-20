unit CKeditor;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.OleCtrls, SHDocVw, MSHTML,
  Vcl.StdCtrls,
  System.IOUtils;

type
  TCKeditor = class(TWebBrowser)
    procedure setTemplateFile(filename: string);
  private
    { Private declarations }
    filename: string;
    Fhtml: WideString;
    function getHTML: WideString;
    procedure setHTML(html: WideString);
    function getTemplateFile: string;
    function LoadFileToStr(const filename: TFileName): String;
    function GetElementById(const Doc: IDispatch; const Id: string): IDispatch;
    procedure callJS();

  protected
    { Protected declarations }
  public
    { Public declarations }
    property html: WideString read getHTML write setHTML;
    property templateFile: string read getTemplateFile write setTemplateFile;
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('HTML Elements', [TCKeditor]);
end;

{ TTinyMce }

function TCKeditor.getHTML: WideString;
var
  Elem: IHTMLElement;
begin
  self.callJS;
  Elem := GetElementById(self.Document, 'returnedData') as IHTMLElement;
  if Assigned(Elem) then
    Result := Elem.innerHTML;
end;

procedure TCKeditor.setHTML(html: WideString);
var
  str: string;
begin
  str := LoadFileToStr(ExtractFilePath(self.filename) +
    'ui/ckeditor/init/temp.html');
  self.Fhtml := StringReplace(str, '{editor}', html, [rfIgnoreCase]);
end;

function TCKeditor.LoadFileToStr(const filename: TFileName): String;
var
  FileStream: TFileStream;
  Bytes: TBytes;

begin
  Result := '';
  FileStream := TFileStream.Create(filename, fmOpenRead or fmShareDenyWrite);
  try
    if FileStream.size > 0 then
    begin
      SetLength(Bytes, FileStream.size);
      FileStream.Read(Bytes[0], FileStream.size);
    end;
    Result := TEncoding.ASCII.GetString(Bytes);
  finally
    FileStream.Free;
  end;
end;


procedure TCKeditor.callJS();
  { Calls JavaScript foo() function }
var
  Doc: IHTMLDocument2;      // current HTML document
  HTMLWindow: IHTMLWindow2; // parent window of current HTML document
  JSFn: string;             // stores JavaScipt function call
begin
  // Get reference to current document
  Doc := self.Document as IHTMLDocument2;
  if not Assigned(Doc) then
    Exit;
  // Get parent window of current document
  HTMLWindow := Doc.parentWindow;
  if not Assigned(HTMLWindow) then
    Exit;
  // Run JavaScript
  try
    //JSFn := Format('post("%s",%d)', [S, I]);  // build function call
    HTMLWindow.execScript('getData()', 'JavaScript'); // execute function
  except
    // handle exception in case JavaScript fails to run
  end;
end;

function TCKeditor.getTemplateFile: string;
begin
  Result := self.templateFile;
end;

procedure TCKeditor.setTemplateFile(filename: string);
var
  ss: TStringStream;
begin
  // self.templateFile := filename;
  self.filename := filename;

  ss := TStringStream.Create(self.Fhtml, TEncoding.UTF8);
  ss.SaveToFile(self.filename);

  self.Navigate('file:///' + filename);
end;

function TCKeditor.GetElementById(const Doc: IDispatch; const Id: string)
  : IDispatch;
var
  Document: IHTMLDocument2; // IHTMLDocument2 interface of Doc
  Body: IHTMLElement2; // document body element
  Tags: IHTMLElementCollection; // all tags in document body
  Tag: IHTMLElement; // a tag in document body
  I: integer; // loops thru tags in document body
begin
  Result := nil;
  // Check for valid document: require IHTMLDocument2 interface to it
  if not Supports(Doc, IHTMLDocument2, Document) then
    raise Exception.Create('Invalid HTML document');
  // Check for valid body element: require IHTMLElement2 interface to it
  if not Supports(Document.Body, IHTMLElement2, Body) then
    raise Exception.Create('Can''t find <body> element');
  // Get all tags in body element ('*' => any tag name)
  Tags := Body.getElementsByTagName('*');
  // Scan through all tags in body
  for I := 0 to Pred(Tags.Length) do
  begin
    // Get reference to a tag
    Tag := Tags.item(I, EmptyParam) as IHTMLElement;
    // Check tag's id and return it if id matches
    if AnsiSameText(Tag.Id, Id) then
    begin
      Result := Tag;
      Break;
    end;
  end;
end;

end.
