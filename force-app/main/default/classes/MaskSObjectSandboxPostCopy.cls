global with sharing class MaskSObjectSandboxPostCopy implements SandboxPostCopy {

	global void runApexClass(SandboxContext context) {
		MaskSObjectUtils.executeBatch('%');
	}
}
