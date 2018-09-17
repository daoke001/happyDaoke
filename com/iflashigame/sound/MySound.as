package com.iflashigame.sound 
{
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.system.ApplicationDomain;
	/**
	 * 声音管理类
	 * @author faster
	 */
	public class MySound
	{
		private static var _instance:MySound;
		
		private var _sound:Sound;
		private var _soundName:String;
		private var _soundChanel:SoundChannel;
		
		public var bkDisabled:Boolean;		//禁止播放背景音
		public var eventDisabled:Boolean;	//禁止播放音效
		
		public function MySound(singletonEnforcer:SingletonEnforcer) 
		{
			
		}
		
		/**
		 * 取得单利
		 * @return
		 */
		public static function getInstance():MySound
		{
			if (MySound._instance == null)
			{
				MySound._instance = new MySound(new SingletonEnforcer);
			}
			return MySound._instance;
		}
		
		/**
		 * 设置不同的声音对象
		 * @param	sound	需要播放的声音对象
		 * @param	loop	声音的循环次数
		 */
		public function start(soundName:String,sound:Sound,loop:int=999)
		{
			if (_soundChanel != null)
			{
				_soundChanel.stop();
			}
			_sound = sound;
			if (!bkDisabled)
			{
				_soundName = soundName;
				_soundChanel = _sound.play(0, loop);
			}
		}
		
		/**
		 * 通过名称播放音乐
		 * @param	soundName
		 * @param	loop
		 */
		public function startByName(soundName:String, loop:int = 999)
		{
			if (_soundName == soundName) return;
			var soundClass:Class = ApplicationDomain.currentDomain.getDefinition(soundName) as Class;
			start(soundName,new soundClass as Sound, loop);
		}
		
		/**
		 * 播放事件声音
		 * @param	sound	需要播放的事件声音对象
		 */
		public function startEventSound(sound:Sound)
		{
			if(!eventDisabled)
			sound.play();
		}
		
		/**
		 * 通过名称播放时间音乐
		 * @param	soundName
		 */
		public function startEventSoundByName(soundName:String)
		{
			var soundClass:Class = ApplicationDomain.currentDomain.getDefinition(soundName) as Class;
			startEventSound(new soundClass as Sound);
		}
		
		/**
		 * 使背景声音停止
		 */
		public function stop(soundName:String="")
		{
			if (_soundChanel != null)
			{
				if(soundName=="")
				_soundChanel.stop();
				else if (soundName == _soundName)
				_soundChanel.stop();
				_soundName = "";
			}
		}
		
		/**
		 * 获取当前音乐的长度
		 * @return
		 */
		public function getLength():Number
		{
			if (_sound == null) return 0;
			else return _sound.length;
		}
		
		/**
		 * 取得当前播放的位置
		 * @return
		 */
		public function getPosition():Number
		{
			if (_soundChanel == null || _sound == null) return 0;
			else return _soundChanel.position;
		}
		
	}
}
class SingletonEnforcer{}