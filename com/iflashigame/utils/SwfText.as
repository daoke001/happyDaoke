package com.iflashigame.utils
{
	
	/**
	 * 解决wmode为opaque时在非ie浏览器下无法输入中文的问题
	 * @author Gray Liao
	 */
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.geom.Point;
	import flash.external.ExternalInterface;
	import fl.managers.FocusManager;
	public class SwfText 
	{
		private var _target:DisplayObject;
		private var _container:String;
		private var _isIE:Boolean;
		private var fm:FocusManager;
		public function SwfText(target:DisplayObjectContainer, container:String)
		{
			_target = target;
			_container = container;
			_isIE = ExternalInterface.call(JSScripts.isIE);
			fm = new FocusManager(target);
			ExternalInterface.addCallback("setFieldTxt",setFieldTxt);
		}
		
		public function addTextField(textField:TextField):void
		{
			textField.addEventListener(FocusEvent.FOCUS_IN, focusChange);
		}
		
		public function removeTextField(textField:TextField):void
		{
			textField.removeEventListener(FocusEvent.FOCUS_IN, focusChange);
		}
		
		private function showForm(params):void
		{
			ExternalInterface.call(JSScripts.showForm,params);
		}
		
		private function setFieldTxt(fieldName:String, txt:String):void
		{
			_target[fieldName].text = txt == "null" ? "" : txt;
			fm.setFocus(null);
		}
		
		private function focusChange(e:FocusEvent):void 
		{
			if (_isIE)
			{
				return;
			}
			var textField:TextField = e.target as TextField;
			//var txtFormat:TextFormat = textField.getTextFormat();
			var txtFormat:TextFormat = textField.defaultTextFormat;
			var type:String;
			var localPos:Point = new Point(textField.x, textField.y);
			var globalPos:Point = _target.localToGlobal(localPos);
			var maxLength:String;
			if (textField.displayAsPassword)
			{
				type = "password";
			}else {
				type = "text";
			}
			if (textField.maxChars < 1)
			{
				maxLength = "";
			}else {
				maxLength = textField.maxChars.toString();
			}
			setTimeout(showForm, 1, {x: globalPos.x, y: globalPos.y, w: textField.width, h: textField.height,
			filedName: textField.name, txt: textField.text, size: txtFormat.size, align: txtFormat.align, type: type, 
			multiline: textField.multiline, color: rgbToHex(textField.textColor), maxLength: maxLength, contener: _container, font:txtFormat.font } );
			textField.text = "";
		}
		
		private function rgbToHex(color:uint):String{
			// Find hex number in the RGB offset
			var colorInHex:String = color.toString(16);
			var c:String = "00000" + colorInHex;
			var e:int = c.length;
			c = c.substring(e - 6, e);
			return "#"+ c.toUpperCase();
		}
	}
	
}

class JSScripts
{ 
	public static var isIE:XML = new XML(
		<script>
			<![CDATA[
				function ()
				{
					var isInternetExplorer = navigator.appName.indexOf("Microsoft") != -1;
					return isInternetExplorer;
				}
			]]>
		</script>
	);
				
				
	public static var showForm:XML = new XML(
		<script>
			<![CDATA[
				function (params)
				{
					var node = null;
					// input basics
					var contener = params.contener;
					if (params.multiline) 
					{
						node = document.createElement("TEXTAREA");
					}else {
						node = document.createElement("INPUT");
					}
					node.setAttribute("type",params.type);
					node.setAttribute("id","INPUT");
					node.setAttribute("swf", contener);
					node.setAttribute("maxlength",params.maxLength);
					node.fieldName = params.filedName;
					node.value = params.txt == "null" ? "" : params.txt;
					node.style.visibility = "visible";
					node.style.position = "absolute";
					node.style.border = "none";
					node.style.left = params.x + "px";
					node.style.top = params.y + "px";
					node.style.width = params.w + "px";
					node.style.height = params.h + "px";
					node.style.fontSize = params.size + "px";
					node.style.fontFamily = params.font;
					node.style.textAlign = params.align;
					node.style.color = params.color;
					node.style.background = "none";
					
					// event handler
					node.onkeyup = function()
								{
									/*if (event.keyCode == 13) //enter
									{ 
										this.onblur();
									}*/
								};
					node.onblur = function()
								{
									//var isInternetExplorer = navigator.appName.indexOf("Microsoft") != -1;
									//var flashObj = isInternetExplorer ? document.all.flashContent : document.flashContent;
									var flashObj = document.getElementById(contener);
									if (flashObj == null || flashObj == undefined)
									{
										flashObj = swfobject.getObjectById(contener);
									}
									flashObj.setFieldTxt(this.fieldName, this.value);
									flashObj.focus();
									document.getElementsByTagName('BODY')[0].removeChild( node );
								};
					
					// attatch to DOM
					document.getElementsByTagName('BODY')[0].appendChild( node );
					node.focus();
				}
			]]>
		</script>
	);
}