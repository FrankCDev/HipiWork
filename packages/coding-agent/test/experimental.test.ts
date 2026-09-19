import { afterEach, describe, expect, it } from "vitest";
import { areExperimentalFeaturesEnabled } from "../src/core/experimental.ts";

describe("areExperimentalFeaturesEnabled", () => {
	const originalPiExperimental = process.env.HIPI_EXPERIMENTAL;

	afterEach(() => {
		if (originalPiExperimental === undefined) {
			delete process.env.HIPI_EXPERIMENTAL;
		} else {
			process.env.HIPI_EXPERIMENTAL = originalPiExperimental;
		}
	});

	it("returns false when HIPI_EXPERIMENTAL is unset", () => {
		delete process.env.HIPI_EXPERIMENTAL;

		expect(areExperimentalFeaturesEnabled()).toBe(false);
	});

	it("returns false when HIPI_EXPERIMENTAL is empty", () => {
		process.env.HIPI_EXPERIMENTAL = "";

		expect(areExperimentalFeaturesEnabled()).toBe(false);
	});

	it("returns true when HIPI_EXPERIMENTAL is set to 1", () => {
		process.env.HIPI_EXPERIMENTAL = "1";

		expect(areExperimentalFeaturesEnabled()).toBe(true);
	});

	it("returns false when HIPI_EXPERIMENTAL is set to 0", () => {
		process.env.HIPI_EXPERIMENTAL = "0";

		expect(areExperimentalFeaturesEnabled()).toBe(false);
	});

	it("returns false when HIPI_EXPERIMENTAL is set to a non-1 value", () => {
		process.env.HIPI_EXPERIMENTAL = "true";

		expect(areExperimentalFeaturesEnabled()).toBe(false);
	});
});
