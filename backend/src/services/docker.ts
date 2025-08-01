import { exec } from "child_process";
import fs from "fs/promises";
import path from "path";
import { promisify } from "util";

const execAsync = promisify(exec);
const BASE_PORT = 8000;

const usedPorts = new Set<number>();

async function getAllAssignedPorts(): Promise<number[]> {
  try {
    const { stdout } = await execAsync(`docker ps --format "table {{.Names}}\\t{{.Ports}}" --filter "label=project=december"`);
    const lines = stdout.split('\n').slice(1); // Skip header
    const ports: number[] = [];
    
    for (const line of lines) {
      if (line.trim()) {
        const portMatch = line.match(/0\.0\.0\.0:(\d+)->/);
        if (portMatch) {
          ports.push(parseInt(portMatch[1]));
        }
      }
    }
    return ports;
  } catch (error) {
    console.log("Error getting assigned ports:", error);
    return [];
  }
}

async function findAvailablePort(
  startPort: number = BASE_PORT
): Promise<number> {
  const assignedPorts = await getAllAssignedPorts();
  const allUsedPorts = new Set([...usedPorts, ...assignedPorts]);

  for (let port = startPort; port < startPort + 1000; port++) {
    if (!allUsedPorts.has(port) && (await isPortAvailable(port))) {
      usedPorts.add(port);
      return port;
    }
  }
  throw new Error("No available ports found");
}

async function isPortAvailable(port: number): Promise<boolean> {
  try {
    const { stdout } = await execAsync(`lsof -i :${port}`);
    return stdout.trim() === "";
  } catch {
    return true;
  }
}

function releasePort(port: number): void {
  usedPorts.delete(port);
}

export async function getDockerfile(): Promise<string> {
  return await fs.readFile("./src/Dockerfile", "utf-8");
}

export async function buildImage(containerId: string): Promise<string> {
  const tempDir = path.join("/tmp", `docker-app-${containerId}`);
  await fs.mkdir(tempDir, { recursive: true });

  try {
    const dockerfileContent = await getDockerfile();
    await fs.writeFile(path.join(tempDir, "Dockerfile"), dockerfileContent);

    const imageName = `dec-nextjs-${containerId}`;
    console.log(`Building image: ${imageName}`);

    // Use CLI instead of dockerode
    const { stdout, stderr } = await execAsync(
      `docker build -t ${imageName} --rm --force-rm ${tempDir}`
    );
    
    console.log("Build output:", stdout);
    if (stderr) console.log("Build stderr:", stderr);

    return imageName;
  } catch (error) {
    console.error("Docker build failed:", error);
    throw new Error(`Docker build failed: ${error}`);
  } finally {
    // Clean up temp directory
    try {
      await fs.rm(tempDir, { recursive: true, force: true });
    } catch (cleanupError) {
      console.warn("Failed to clean up temp directory:", cleanupError);
    }
  }
}

export async function runContainer(
  imageName: string,
  containerId: string,
  files: { [path: string]: string }
): Promise<{
  containerId: string;
  port: number;
  url: string;
}> {
  const port = await findAvailablePort();
  const containerName = `dec-nextjs-${containerId}`;

  try {
    // Create temporary directory for files
    const tempDir = path.join("/tmp", `container-files-${containerId}`);
    await fs.mkdir(tempDir, { recursive: true });

    // Write files to temp directory
    for (const [filePath, content] of Object.entries(files)) {
      const fullPath = path.join(tempDir, filePath);
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, content);
    }

    // Run container with CLI
    const { stdout } = await execAsync(
      `docker run -d --name ${containerName} ` +
      `-p ${port}:3000 ` +
      `-v ${tempDir}:/app/src ` +
      `--label project=december ` +
      `--label assignedPort=${port} ` +
      `${imageName}`
    );

    const runningContainerId = stdout.trim();
    console.log(`Container started: ${runningContainerId}`);

    return {
      containerId: runningContainerId,
      port,
      url: `http://localhost:${port}`,
    };
  } catch (error) {
    releasePort(port);
    console.error("Failed to run container:", error);
    throw new Error(`Failed to run container: ${error}`);
  }
}

export async function stopContainer(containerId: string): Promise<void> {
  try {
    // Get container info first
    const { stdout } = await execAsync(`docker inspect ${containerId} --format='{{.Config.Labels.assignedPort}}'`);
    const port = parseInt(stdout.trim());
    if (port) {
      releasePort(port);
    }

    // Stop and remove container
    await execAsync(`docker stop ${containerId}`);
    await execAsync(`docker rm ${containerId}`);
    
    console.log(`Container stopped and removed: ${containerId}`);
  } catch (error) {
    console.error("Failed to stop container:", error);
    throw new Error(`Failed to stop container: ${error}`);
  }
}

export async function getContainerLogs(containerId: string): Promise<string> {
  try {
    const { stdout } = await execAsync(`docker logs ${containerId}`);
    return stdout;
  } catch (error) {
    console.error("Failed to get container logs:", error);
    return `Failed to get logs: ${error}`;
  }
}

export async function listContainers(): Promise<Array<{
  id: string;
  name: string;
  status: string;
  port?: number;
}>> {
  try {
    const { stdout } = await execAsync(
      `docker ps -a --format "{{.ID}}\\t{{.Names}}\\t{{.Status}}\\t{{.Ports}}" --filter "label=project=december"`
    );
    
    const lines = stdout.split('\n').filter(line => line.trim());
    return lines.map(line => {
      const [id, name, status, ports] = line.split('\t');
      const portMatch = ports?.match(/0\.0\.0\.0:(\d+)->/);
      const port = portMatch ? parseInt(portMatch[1]) : undefined;
      
      return {
        id: id.trim(),
        name: name.trim(),
        status: status.trim(),
        port
      };
    });
  } catch (error) {
    console.error("Failed to list containers:", error);
    return [];
  }
}

export async function updateContainerFiles(
  containerId: string,
  files: { [path: string]: string }
): Promise<void> {
  try {
    // Create temporary directory for updated files
    const tempDir = path.join("/tmp", `update-${containerId}-${Date.now()}`);
    await fs.mkdir(tempDir, { recursive: true });

    // Write files to temp directory
    for (const [filePath, content] of Object.entries(files)) {
      const fullPath = path.join(tempDir, filePath);
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, content);
    }

    // Copy files to container
    for (const filePath of Object.keys(files)) {
      const srcPath = path.join(tempDir, filePath);
      const destPath = `/app/src/${filePath}`;
      await execAsync(`docker cp ${srcPath} ${containerId}:${destPath}`);
    }

    // Clean up temp directory
    await fs.rm(tempDir, { recursive: true, force: true });
    
    console.log(`Updated files in container: ${containerId}`);
  } catch (error) {
    console.error("Failed to update container files:", error);
    throw new Error(`Failed to update container files: ${error}`);
  }
}

export async function getContainerFiles(
  containerId: string,
  filePath: string
): Promise<string> {
  try {
    const { stdout } = await execAsync(`docker exec ${containerId} cat /app/src/${filePath}`);
    return stdout;
  } catch (error) {
    console.error("Failed to get container file:", error);
    throw new Error(`Failed to get container file: ${error}`);
  }
}

export async function execInContainer(
  containerId: string,
  command: string
): Promise<string> {
  try {
    const { stdout } = await execAsync(`docker exec ${containerId} ${command}`);
    return stdout;
  } catch (error) {
    console.error("Failed to execute in container:", error);
    throw new Error(`Failed to execute in container: ${error}`);
  }
}
