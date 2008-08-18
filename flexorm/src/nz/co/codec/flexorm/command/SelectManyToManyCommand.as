package nz.co.codec.flexorm.command
{
    import flash.data.SQLConnection;
    import flash.events.SQLEvent;

    import mx.utils.ObjectUtil;

    public class SelectManyToManyCommand extends SQLParameterisedCommand
    {
        private var _associationTable:String;

        private var _indexColumn:String;

        private var _joins:Object;

        private var _result:Array;

        public function SelectManyToManyCommand(
            sqlConnection:SQLConnection,
            schema:String,
            table:String,
            associationTable:String,
            indexColumn:String=null,
            debugLevel:int=0)
        {
            super(sqlConnection, schema, table, debugLevel);
            _associationTable = associationTable;
            _indexColumn = indexColumn;
            _joins = {};
        }

        public function clone():SelectManyToManyCommand
        {
            var copy:SelectManyToManyCommand = new SelectManyToManyCommand(_sqlConnection, _schema, _table, _associationTable, _indexColumn, _debugLevel);
            copy.columns = ObjectUtil.copy(_columns);
            copy.filters = ObjectUtil.copy(_filters);
            copy.joins = ObjectUtil.copy(_joins);
            return copy;
        }

        protected function set joins(value:Object):void
        {
            _joins = value;
        }

        public function addJoin(fk:String, pk:String):void
        {
            _joins[fk] = pk;
            _changed = true;
        }

        override protected function prepareStatement():void
        {
            if (_joins == null)
                throw new Error("Join columns on SelectManyToManyCommand not set. ");

            var sql:String = "select ";
            for (var column:String in _columns)
            {
                sql += "a." + column + ",";
            }
            sql = sql.substring(0, sql.length - 1); // remove last comma
            sql += " from " + _schema + "." + _table +
                " a inner join " + _schema + "." + _associationTable + " b on ";

            for (var fk:String in _joins)
            {
                sql += "b." + fk + "=a." + _joins[fk] + " and ";
            }
            sql = sql.substring(0, sql.length - 5); // remove last ' and '

            if (_filters)
            {
                sql += " where ";
                for (var filter:String in _filters)
                {
                    sql += "b." + filter + "=" + _filters[filter] + " and ";
                }
                sql = sql.substring(0, sql.length - 5); // remove last ' and '
            }
            if (_indexColumn)
                sql += " order by b." + _indexColumn;

            _statement.text = sql;
            _changed = false;
        }

        override protected function respond(event:SQLEvent):void
        {
            _result = _statement.getResult().data;
            _responder.result(_result);
        }

        override public function execute():void
        {
            super.execute();
            if (_responder == null)
                _result = _statement.getResult().data;
        }

        public function get result():Array
        {
            return _result;
        }

        public function toString():String
        {
            return "SELECT MANY-TO-MANY " + _table + ": " + _statement.text;
        }

    }
}