import { load as parseYaml } from 'js-yaml'

// 首部 YAML frontmatter：--- 起止，块内含键值行
const FRONTMATTER_RE = /^---\r?\n([\s\S]*?)\r?\n---[ \t]*\r?\n?/

function matchFrontmatter(md: string): RegExpMatchArray | null {
  const match = md.replace(/\r\n/g, '\n').match(FRONTMATTER_RE)
  // 块内无键值行时视为普通分隔线，不作元数据
  if (!match || !/^[A-Za-z_][\w-]*\s*:/m.test(match[1])) return null
  return match
}

// 解析 title / description，无元数据或解析失败返回 null
export function parseFrontmatter(md: string): { title: string; description: string } | null {
  const match = matchFrontmatter(md)
  if (!match) return null

  let data: unknown
  try {
    data = parseYaml(match[1])
  } catch {
    return null
  }
  if (typeof data !== 'object' || data === null) return null

  const text = (value: unknown) => (typeof value === 'string' ? value.trim() : '')
  const { title, description } = data as Record<string, unknown>
  const parsed = { title: text(title), description: text(description) }
  if (!parsed.title && !parsed.description) return null
  return parsed
}

// 去掉首部 frontmatter，只留正文
export function stripFrontmatter(md: string): string {
  const match = matchFrontmatter(md)
  if (!match) return md
  return md.replace(/\r\n/g, '\n').slice(match[0].length)
}
