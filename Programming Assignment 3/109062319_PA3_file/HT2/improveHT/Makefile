COVERAGES = line+cond+tgl+fsm+branch

.PHONY: com sim cov clean
com: simv
sim: simv.vdb/snps/coverage/db/testdata
cov: simv.vdb/snps/coverage/db/testdata
	verdi -cov -covdir simv.vdb
clean:
	rm -rf csrc simv*

# Note: either aes_top.v or tb.v must be the first file
simv: aes_top.v aes_128.v round.v table.v tb.v
	vcs $^ -cm $(COVERAGES) -full64
	rm -f .fsm.sch.verilog.xml
simv.vdb/snps/coverage/db/testdata: simv
	./$< -cm $(COVERAGES)
	rm -f ucli.key
