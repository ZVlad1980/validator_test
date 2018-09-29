create or replace package etl_api is

  -- Author  : ACER E15
  -- Created : 29.09.2018 7:04:58
  -- Purpose : 

  /**
   * ��������� validate_data ��������� �������� ������ ������� �� ��������� ������
   *   ��� ������ ������� �� ��������� � �������� � ������� � EXCEPTIONS ������ � ������� 
   *     �������������� (��� ������, �������� �� ������� �������) 
   *   ����� ������� ������� ������������ ��� ���� ���� ������� ���������-������������ ���� ������ �� 
   *     ������� �������.
   *   ���� ����� ��������� � ������� ������� ������� ������ ���������� ���� ���������, 
   *     �� ������ � EXCEPTIONS ������� �������� ���� �������.
   * ������� ���������� ������ � EXCEPTIONS ������������ �� ����� ID_XREF+XREF_TABLE_NAME +ERR_ID+SRC_KEY_VAL.
   *
   * p_base_table     - ��� ��������� �������
   * p_base_col       - ��������� ���� ��� ���������
   * p_validate_table - ��� ������� �������
   * p_validate_col   - ���� ��� ��������� �� ������� �������
   * p_join_col       - Join Constraint: ID_XREF ���� OBJ_ID (������: PRODUCT_XREF.ID_XREF=AUTHORS.ID_XREF)
   * p_err_nm         - ��� ������ ERR_NM
   * p_validate_stmt  - ��������������. ������������� Constraint ������������ ���������� � �������� (������: PRODUCT_XREF.OUT_OF_PRINT_DATE = AUTHORS.END_DATE)
   *                    ���� Constraint �� ��������, �� ������� ������ �� ��������� � ��������.
   *                    ������������� Constraint ����� ���� ������� � �������� �� ���������� ��������� �� ���������� �����.
   *                    ���� �� ����� - ���������� ����� p_base_col = p_validate_col
   * 
   */
  procedure validate_data(
     p_base_table     varchar2,
     p_base_col       varchar2,
     p_validate_table varchar2,
     p_validate_col   varchar2,
     p_join_col       varchar2,
     p_err_nm         varchar2,
     p_validate_stmt  varchar2 default null
  );
  
end etl_api;
/
