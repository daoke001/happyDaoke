package com.iflashigame.utils 
{
	/**
	 * 关键词过滤
	 * @author faster
	 */
	public class TextFilter
	{
		private static var _instance:TextFilter;
		private var _filterArr:Array;
		public var keyFlag:String = "*";		//默认的替换字符
		
		public function TextFilter(singletonEnforcer:SingletonEnforcer) 
		{
			
		}
		
		public static function getInstance():TextFilter
		{
			if (TextFilter._instance == null)
			{
				TextFilter._instance = new TextFilter(new SingletonEnforcer);
			}
			return TextFilter._instance;
		}
		
		/**
		 * 设置关键词组
		 * @param	str
		 */
		public function setStr(str:String)
		{
			str = str.replace(/\s+/g, "#");
			_filterArr = str.split("#");
		}
		
		/**
		 * 检测字符串中是否包含了敏感字词
		 * @param	str
		 * @return
		 */
		public function checkText(str:String):Boolean
		{
			if (_filterArr == null) return true;
			
			for(var i in _filterArr)
			{
				if (str.indexOf(_filterArr[i]) != -1)
				{
					return false;
				}
			}
			return true;
		}
		
		/**
		 * 将字符串中的敏感词替换成指定的符号
		 * @param	str
		 * @return
		 */
		public function replaceText(str:String):String
		{
			if (_filterArr == null) return str;
			for (var i in _filterArr)
			{
				var myPattern:RegExp = new RegExp(_filterArr[i], "g");
				str = str.replace(myPattern, getFlag(_filterArr[i].length));
			}
			return str;
		}
		
		private function getFlag(length:int):String
		{
			var str:String=""
			while (length > 0)
			{
				str += keyFlag;
				length--;
			}
			return str;
		}
		
		/**
		 * 将查找到的字符串替换成指定的字符
		 * @return
		 */
		private function getStar():String
		{
			var length=arguments[0].length
			var str:String="";
			for(var i=0;i<length;i++)
			{
				str+=keyFlag;
			}
			return str;
		}		
	}

}
class SingletonEnforcer{}