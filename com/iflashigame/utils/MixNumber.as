package com.iflashigame.utils 
{
	import flash.utils.getTimer;
	/**
	 * 混淆的浮点型类
	 * @author 闪刀浪子
	 */
	public class MixNumber 
	{
		
		private var _obj:Object;
		private var _timer:String;
		public function MixNumber(val:Number=0) 
		{
			_timer = getTimer().toString();
			setValue(val);
		}
		
		public function getValue():Number
		{
			var str:String = _obj.value;
			_obj = { value:str };
			return Number(str.substr(0,str.length-_timer.length));
		}
		
		public function setValue(val:Number)
		{
			var tmpObj:Object = { value:val.toString()+_timer };
			_obj = { value:tmpObj.value };
		}
		
		public function toString():String
		{
			return getValue().toString();
		}
		
	}

}