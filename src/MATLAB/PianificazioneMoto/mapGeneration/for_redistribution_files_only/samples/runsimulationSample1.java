import com.mathworks.toolbox.javabuilder.*;
import mapGeneration.Map;
import mapGeneration.Path;
import mapGeneration.Simulate;

/**
 *
 * Sample driver code that is integrated with a compiled MATLAB function
 * generated by MATLAB Compiler SDK.
 *
 * Refer to the MATLAB Compiler SDK documentation for more
 * information.
 *
 * @see com.mathworks.toolbox.javabuilder.MWArray
 *
 */
public class runsimulationSample1 {

	private static Map mapInstance;
	private static Path pathInstance;
	private static Simulate simulateInstance;

	private static void setup() throws MWException {
		mapInstance = new Map();
		pathInstance = new Path();
		simulateInstance = new Simulate();
	}

	/**
	 * Sample code for {@link Simulate#runsimulation(int, Object...)}.
	 */
	public static void runsimulationExample() {
		MWArray MIn = null;
		MWArray alphaIn = null;
		MWNumericArray qrOut = null;
		MWNumericArray dqrOut = null;
		MWNumericArray ddqrOut = null;
		MWNumericArray eOut = null;
		Object[] results = null;
		try {
			double MInData = 10.0;
			MIn = new MWNumericArray(MInData, MWClassID.DOUBLE);
			double alphaInData = 200.0;
			alphaIn = new MWNumericArray(alphaInData, MWClassID.DOUBLE);
			results = simulateInstance.runsimulation(4, MIn, alphaIn);
			if (results[0] instanceof MWNumericArray) {
				qrOut = (MWNumericArray) results[0];
			}
			if (results[1] instanceof MWNumericArray) {
				dqrOut = (MWNumericArray) results[1];
			}
			if (results[2] instanceof MWNumericArray) {
				ddqrOut = (MWNumericArray) results[2];
			}
			if (results[3] instanceof MWNumericArray) {
				eOut = (MWNumericArray) results[3];
			}
			System.out.println(qrOut);
			System.out.println(dqrOut);
			System.out.println(ddqrOut);
			System.out.println(eOut);
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			// Dispose of native resources
			MWArray.disposeArray(MIn);
			MWArray.disposeArray(alphaIn);
			MWArray.disposeArray(results);
		}
	}

	public static void main(String[] args) {
		try {
			setup();
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		try {
			runsimulationExample();
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		} finally {
			// Dispose of native resources
			mapInstance.dispose();
			// Dispose of native resources
			pathInstance.dispose();
			// Dispose of native resources
			simulateInstance.dispose();
		}
	}

}
