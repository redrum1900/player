package models
{

	public class LogVO
	{
		public static const WARNING:int=1;
		public static const NORMAL:int=2;
		public static const CLEAR_CACHE:int=3;
		public static const RECORD_DM:int=4;
		public static const PLAY_RECORDED_DM:int=5;
		public static const AUTO_UPDATE_BEGIN:int=6;
		public static const AUTO_UPDATE_END:int=7;
		public static const REBOOT_AUTO_UPDATE:int=8;
		public static const REBOOT_BY_COMMAND:int=9;


		/**
		 *
		 * @param type 日志类型
		 * @param value 日志的值
		 * @param info 日志的信息
		 *
		 */
		public function LogVO(type:int, value:Object, info:String='')
		{
			this.type=type;
			this.value=value + '';
			this.info=info;
		}

		public var type:int;
		public var value:String;
		public var info:String;
		public var created_at:Number;
	}
}
