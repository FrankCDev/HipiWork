export function areExperimentalFeaturesEnabled(): boolean {
	return process.env.HIPI_EXPERIMENTAL === "1";
}
