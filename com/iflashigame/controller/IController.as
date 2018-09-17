package com.iflashigame.controller 
{
	import flash.display.DisplayObjectContainer;
	import flash.system.ApplicationDomain;
	
	/**
	 * 通讯控制器接口
	 * @author 闪刀浪子
	 */
	public interface IController 
	{
		function setRoot(root:DisplayObjectContainer, maskCode:String, maskDomain:ApplicationDomain = null)
		function get requestCode():String
		function set requestCode(val:String)
		function get responseCode():String
		function set responseCode(val:String)
		function get serverURL():String
		function set serverURL(val:String)
		function get debug():Boolean 
		function set debug(value:Boolean):void 
		function get test():Boolean 
		function set test(value:Boolean):void
		function sendJSON(data:Object, listener:Function, url:String = null):String
		function sendJSONToURL(data:Object, url:String=""):String
		function set testInstance(value:IControllerTest):void 
		function get testInstance():IControllerTest
		function get disable():Boolean 
		function set disable(value:Boolean):void 
		
		function close(stamp:String)
		function addEventListener(type:String, listener:Function,
									useCapture:Boolean = false, priority:int = 0,
									useWeakReference:Boolean = false):void
		function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
	}
}