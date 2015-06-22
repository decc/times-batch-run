require 'minitest/autorun'
require_relative '../lib/list_of_cases'
require 'pp'

class TestListOfCases < MiniTest::Test

  def setup
@tsv =<<END
# This is a list of cases
# It was prepared by Tom in 2015

# This is the header
CaseName	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Always	Discount rate	CB3	CB4	CB5	2050Target	Nuclear	CCS	Renewables Target

# These are the cases
cases11ya	base	newagr	newelc	newind	newprc	newres	newrsr	newser	newtra	refscenario	syssettings	uc_base	uc_elc	uc_ind	uc_prc	uc_res	uc_rsr	uc_ser	uc_tra	discount_stern	cb3-hit	cb4-missed	cb5-1000	2050-target-hit	NIL	NIL	re_target

cases124h	base	newagr	newelc	newind	newprc	newres	newrsr	newser	newtra	refscenario	syssettings	uc_base	uc_elc	uc_ind	uc_prc	uc_res	uc_rsr	uc_ser	uc_tra	discount_stern	cb3-hit	cb4-missed	cb5-1100	2050-target-hit	NIL	NIL	NIL
cases1287	base	newagr	newelc	newind	newprc	newres	newrsr	newser	newtra	refscenario	syssettings	uc_base	uc_elc	uc_ind	uc_prc	uc_res	uc_rsr	uc_ser	uc_tra	discount_stern	cb3-hit	cb4-missed	cb5-1100	2050-target-abandoned	NIL	NIL	NIL

# The following case is a bit different
cases14i	base	newagr	newelc	newind	newprc	newres	newrsr	newser	newtra	refscenario	syssettings	uc_base	uc_elc	uc_ind	uc_prc	uc_res	uc_rsr	uc_ser	uc_tra	discount_private	cb3-beat	cb4-missed	cb5-1500	2050-target-abandoned	NIL	NIL	re_target
END

    @list_of_cases = ListOfCases.new
    @list_of_cases.stub :load_file_from_disk, @tsv do
      @list_of_cases.load('cases.tsv')
    end
  end

  def test_case_names
    assert_equal ['cases11ya', 'cases124h', 'cases1287', 'cases14i'], @list_of_cases.case_names
  end

  def test_header
    assert_equal ["CaseName", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Always", "Discount rate", "CB3", "CB4", "CB5", "2050Target", "Nuclear", "CCS", "Renewables Target"], @list_of_cases.header

  end


end

