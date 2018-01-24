/*
	The intent of this is to be a configurable voxel system.
	When this is released, people using the toolkit should not edit this file, they should use the built in configuration methods.
	
	Stuff that isn't/won't be configurable:
		block size (40 units)
		map size (800 blocks^3)
		geometry chunk size(?) (8 blocks^3, should this be changed?)
*/

/*
	Todo List:
		frustum culling (maybe?)
		lighting
		physics
		block metadata
		more rendering options
		transparent blocks that don't break rendering
		tile entities
		block place/remove functions
		networking
		default block values (using heightmap or octree)
*/

AddCSLuaFile()

ENT.Type   = "anim"
ENT.PrintName = "Voxel System"
ENT.Category = "-Voxels"

ENT.Spawnable = true
ENT.AdminSpawnable = true

//Dev config start -- this should contain default config stuff, and should NOT contain a list of block types when finished

ENT.blur_textures= false
ENT.render_dist= 10

ENT.build_quota= 10 //Maximum number of MS to spend building chunk mesh per frame.

ENT.default_heightmap = Material("vox_heightmap.png")

local grassproto = {td=3,t3=0,t6=2,c3=Color(200,255,100)}
local dirtproto = {td=2}
local stoneproto = {td=1}
local dingusproto = {td=50}

ENT.block_types = {}
ENT.block_types[0]={} //Air, this should actually be here by default
ENT.block_types[1]={
	occluder=true,
	build=function(sys)
		sys:PushCuboid(grassproto)
	end
}
ENT.block_types[2]={
	occluder=true,
	build=function(sys)
		sys:PushCuboid(dirtproto)
	end
}
ENT.block_types[3]={
	occluder=true,
	build=function(sys)
		sys:PushCuboid(stoneproto)
	end
}
ENT.block_types[4]={
	occluder=true,
	build=function(sys)
		sys:PushCuboid{td=22,cd=HSVToColor(math.Rand(0,360),1,1)}
	end
}
ENT.block_types[5]={
	occluder=true,
	build=function(sys)
		sys:PushCuboid(dingusproto)
	end
}

//Dev config end

function ENT:Initialize()
	//Make a global variable reference our entity.
	voxsys=self

	//self:SetSolid(SOLID_BBOX)
	//self:SetCollisionBounds(-Vector(500,500,500),Vector(500,500,500))
	self:EnableCustomCollisions(true)

	self:DrawShadow(false)

	self.voxels = {}

	if CLIENT then
		self:SetRenderBounds(Vector(-20,-20,-20),Vector(31980,31980,31980))

		self.chunk_octrees = {}
		//self.chunk_meshes = {} //DEP
		//self.modified_chunks = {} //DEP

		self.rebuild_queue = {}

		self.builder_thread = coroutine.create(function()
			while true do
				if #self.rebuild_queue>0 then
					local ccoords = table.remove(self.rebuild_queue,1)
					self.mod_buffer={}
					
					self:BuildChunk(ccoords)

					table.Merge(self.voxels,self.mod_buffer)
					self.mod_buffer=nil
				else
					coroutine.yield()
				end
			end
		end)

		//test voxels- make a sphere!
		/* (or dont!)
		for x=0,79 do
			for y=0,79 do
				for z=0,79 do
					(self.mod_buffer or self.voxels)[x+y*800+z*640000]= math.sqrt((x-40)^2+(y-40)^2+(z-40)^2)<40 and math.random(1,5) or nil
				end
			end
		end
		*/


		for x=0,9 do
			for y=0,9 do
				for z=0,9 do
					self:FlagChunkForUpdate(x,y,z)
				end
			end
		end
	end
end

//Todo collision detection
function ENT:TestCollision(startpos,delta,isbox,extents)
	if isbox then
		//debugoverlay.Box(startpos, Vector(0,0,0), extents, 10, Color(255,0,0),true)

		//debugoverlay.Box(startpos, Vector(0,0,0), Vector(100,100,100), 10, Color(255,0,0),true)

		//debugoverlay.Box(startpos, Vector(0,0,0), Vector(100,100,100), 10, Color(255,0,255),true)
		//debugoverlay.Box(startpos, Vector(0,0,0), -Vector(100,100,100), 10, Color(255,255,0),true)
	end
	//debugoverlay.Line(startpos,startpos+delta,10,Color(0,255,0),true)
	//debugoverlay.Line(startpos,startpos+delta,10,Color(0,255,0),true)
	//return {}
	/*return {
		HitPos = self:GetPos(),
		Fraction = .01,
		Normal = Vector(0,1,0)
	}*/
end

if CLIENT then
	local atlas = Material("vox_atlas.png")
	local atlas_w = 16
	local atlas_h = 16

	local pixel_bias = 0
	local atlas_xinc = 1/atlas_w-pixel_bias
	local atlas_yinc = 1/atlas_h-pixel_bias

	function ENT:Think()
		self.build_start=SysTime()
		coroutine.resume(self.builder_thread)
	end

	function ENT:FlagChunkForUpdate(cx,cy,cz)
		local ccoords = cx+cy*80+cz*6400
		local vx,vy,vz = self:GetChunkPos(LocalPlayer():GetPos())

		if math.abs(cx-vx)>self.render_dist or math.abs(cy-vy)>self.render_dist or math.abs(cz-vz)>self.render_dist then
			local c = self:OctGet(cx,cy,cz,true)
			c.needs_update = true
		elseif !table.HasValue(self.rebuild_queue,ccoords) then
			table.insert(self.rebuild_queue,ccoords)
		end
	end

	function ENT:TestChunk(cx,cy,cz)
		for x=cx*10,cx*10+9 do
			for y=cy*10,cy*10+9 do
				for z=cz*10,cz*10+9 do
					(self.mod_buffer or self.voxels)[x+y*800+z*640000]= (math.random()<.9) and 1 or nil
				end
			end
		end
		self:FlagChunkForUpdate(cx,cy,cz)
	end

	local function oct_get_r(tree,x,y,z,width,create)
		x=x%width
		y=y%width
		z=z%width

		width=width/2

		local child_addr = (x>=width and 1 or 0) + (y>=width and 2 or 0) + (z>=width and 4 or 0)

		if !tree[child_addr] then
			if create then
				tree[child_addr]={}
				if width!=1 then tree[child_addr][8]=0 end
				tree[8]=tree[8]+1
			else
				return
			end
		end

		return width==1 and tree[child_addr] or oct_get_r(tree[child_addr],x,y,z,width,create)
	end

	function ENT:OctGet(x,y,z,create)
		local root_octree = self.chunk_octrees[math.floor(x/16)+math.floor(y/16)*5+math.floor(z/16)*25]
		if !root_octree then
			if create then
				root_octree={[8]=0}
				self.chunk_octrees[math.floor(x/16)+math.floor(y/16)*5+math.floor(z/16)*25]=root_octree
			else
				return
			end
		end

		return oct_get_r(root_octree,x,y,z,16,create)
	end

	local function oct_delete_r(tree,x,y,z,width)
		x=x%width
		y=y%width
		z=z%width

		width=width/2

		local child_addr = (x>=width and 1 or 0) + (y>=width and 2 or 0) + (z>=width and 4 or 0)

		if !tree[child_addr] then return end
		
		if width == 1 or oct_delete_r(tree[child_addr],x,y,z,width) then
			tree[child_addr]=nil
			tree[8]=tree[8]-1
		end

		if tree[8]==0 then return true end
	end

	function ENT:OctDelete(x,y,z)
		local root_octree = self.chunk_octrees[math.floor(x/16)+math.floor(y/16)*5+math.floor(z/16)*25]
		if !root_octree then return end

		if oct_delete_r(root_octree,x,y,z,16) then
			self.chunk_octrees[math.floor(x/16)+math.floor(y/16)*5+math.floor(z/16)*25]=nil
		end
	end

	function ENT:BuildChunk(ccoords)
		local cx=ccoords%80
		local cy=math.floor((ccoords%6400)/80)
		local cz=math.floor(ccoords/6400)

		self.build_verts={}
		for x=cx*10,cx*10+9 do
			self.build_x = x
			if SysTime()-self.build_start>self.build_quota/1000 then coroutine.yield() end
			for y=cy*10,cy*10+9 do
				self.build_y = y
				for z=cz*10,cz*10+9 do
					local block_id = self:GetData(x,y,z)
					if self.block_types[block_id].build then
						self.build_z = z
						self.block_types[block_id].build(self)
					end
				end
			end
		end

		local chunk_mesh

		if #self.build_verts>0 then
			local chunk_mesh = Mesh()
			chunk_mesh:BuildFromTriangles(self.build_verts)
			local c = self:OctGet(cx,cy,cz,true)
			if c.mesh then c.mesh:Destroy() end
			c.mesh = chunk_mesh
			c.needs_update = nil
		else
			self:OctDelete(cx,cy,cz)
		end
	end

	//A bunch of goofy stuff here is the result of attempts at premature optimization.
	local c_color_white = Color(255,255,255)
	local c_base_scale = Vector(20,20,20)
	local c_v_ppp=Vector(1,1,1)
	local c_v_npp=Vector(-1,1,1)
	local c_v_pnp=Vector(1,-1,1)
	local c_v_ppn=Vector(1,1,-1)
	local c_v_pnn=Vector(1,-1,-1)
	local c_v_npn=Vector(-1,1,-1)
	local c_v_nnp=Vector(-1,-1,1)
	local c_v_nnn=Vector(-1,-1,-1)

	function ENT:PushCuboid(opts)
		opts=opts or {}
		local pos = opts.pos or vector_origin
		local s= opts.scale and opts.scale/2 or c_base_scale

		local voxels = self.voxels
		local build_x = self.build_x
		local build_y = self.build_y
		local build_z = self.build_z
		local offset = Vector(build_x,build_y,build_z)*40
		local build_verts = self.build_verts
		
		//X+
		local t = opts.t1 or opts.td or 0
		local c = opts.c1 or opts.cd or c_color_white
		local adj_block = self.block_types[self:GetData(build_x+1,build_y,build_z)] or {}
		if t==-1 or !(pos.x+s.x==20 and build_x==799 or adj_block.occluder) then
			local tx= (t%atlas_w)/atlas_w
			local ty= math.floor(t/atlas_h)/atlas_h
			local tx2= tx+atlas_xinc
			local ty2= ty+atlas_yinc

			table.Add(build_verts,{
				{pos = offset+pos+s*c_v_pnn, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_ppp, u=tx2, v=ty, color=c},
				{pos = offset+pos+s*c_v_ppn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_ppp, u=tx2, v=ty, color=c},
				{pos = offset+pos+s*c_v_pnn, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_pnp, u=tx, v=ty, color=c}
			})
		end

		//Y+
		t = opts.t2 or opts.td or 0
		c = opts.c2 or opts.cd or c_color_white
		adj_block = self.block_types[self:GetData(build_x,build_y+1,build_z)] or {}
		if t==-1 or !(pos.y+s.y==20 and build_y==799 or adj_block.occluder) then
			local tx= (t%atlas_w)/atlas_w
			local ty= math.floor(t/atlas_h)/atlas_h
			local tx2= tx+atlas_xinc
			local ty2= ty+atlas_yinc

			table.Add(build_verts,{
				{pos = offset+pos+s*c_v_ppp, u=tx, v=ty, color=c},
				{pos = offset+pos+s*c_v_npn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_ppn, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_npn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_ppp, u=tx, v=ty, color=c},
				{pos = offset+pos+s*c_v_npp, u=tx2, v=ty, color=c}
			})
		end

		//Z+
		t = opts.t3 or opts.td or 0
		c = opts.c3 or opts.cd or c_color_white
		adj_block = self.block_types[self:GetData(build_x,build_y,build_z+1)] or {}
		if t==-1 or !(pos.z+s.z==20 and build_z==799 or adj_block.occluder) then
			local tx= (t%atlas_w)/atlas_w
			local ty= math.floor(t/atlas_h)/atlas_h
			local tx2= tx+atlas_xinc
			local ty2= ty+atlas_yinc

			table.Add(build_verts,{
				{pos = offset+pos+s*c_v_nnp, u=tx, v=ty, color=c},
				{pos = offset+pos+s*c_v_ppp, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_pnp, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_ppp, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_nnp, u=tx, v=ty, color=c},
				{pos = offset+pos+s*c_v_npp, u=tx2, v=ty, color=c}
			})
		end

		//X-
		t = opts.t4 or opts.td or 0
		c = opts.c4 or opts.cd or c_color_white
		adj_block = self.block_types[self:GetData(build_x-1,build_y,build_z)] or {}
		if t==-1 or !(pos.x-s.x==-20 and build_x==0 or adj_block.occluder) then
			local tx= (t%atlas_w)/atlas_w
			local ty= math.floor(t/atlas_h)/atlas_h
			local tx2= tx+atlas_xinc
			local ty2= ty+atlas_yinc

			table.Add(build_verts,{
				{pos = offset+pos+s*c_v_npp, u=tx,v=ty, color=c},
				{pos = offset+pos+s*c_v_nnn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_npn, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_nnn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_npp, u=tx,v=ty, color=c},
				{pos = offset+pos+s*c_v_nnp, u=tx2, v=ty, color=c}
			})
		end

		//Y-
		t = opts.t5 or opts.td or 0
		c = opts.c5 or opts.cd or c_color_white
		adj_block = self.block_types[self:GetData(build_x,build_y-1,build_z)] or {}
		if t==-1 or !(pos.y-s.y==-20 and build_y==0 or adj_block.occluder) then
			local tx= (t%atlas_w)/atlas_w
			local ty= math.floor(t/atlas_h)/atlas_h
			local tx2= tx+atlas_xinc
			local ty2= ty+atlas_yinc

			table.Add(build_verts,{
				{pos = offset+pos+s*c_v_nnn, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_pnp, u=tx2,v=ty, color=c},
				{pos = offset+pos+s*c_v_pnn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_pnp, u=tx2,v=ty, color=c},
				{pos = offset+pos+s*c_v_nnn, u=tx, v=ty2, color=c},
				{pos = offset+pos+s*c_v_nnp, u=tx, v=ty, color=c}
			})
		end

		//Z-
		t = opts.t6 or opts.td or 0
		c = opts.c6 or opts.cd or c_color_white
		adj_block = self.block_types[self:GetData(build_x,build_y,build_z-1)] or {}
		if t==-1 or !(pos.z-s.z==-20 and build_z==0 or adj_block.occluder) then
			local tx= (t%atlas_w)/atlas_w
			local ty= math.floor(t/atlas_h)/atlas_h
			local tx2= tx+atlas_xinc
			local ty2= ty+atlas_yinc

			table.Add(build_verts,{
				{pos = offset+pos+s*c_v_ppn, u=tx,v=ty2, color=c},
				{pos = offset+pos+s*c_v_nnn, u=tx2, v=ty, color=c},
				{pos = offset+pos+s*c_v_pnn, u=tx2, v=ty2, color=c},
				{pos = offset+pos+s*c_v_nnn, u=tx2, v=ty, color=c},
				{pos = offset+pos+s*c_v_ppn, u=tx,v=ty2, color=c},
				{pos = offset+pos+s*c_v_npn, u=tx, v=ty, color=c}
			})
		end
	end

	local function oct_render_r(tree,mins,width)
		local maxs = mins+Vector(width*400,width*400,width*400)

		width=width/2

		local center = mins+Vector(width*400,width*400,width*400)

		//CHECK IF WE SHOULD RENDER HERE!
		if width==.5 then
			//CHECK IF WE SHOULD UPDATE HERE!
			tree.mesh:Draw()
		else
			local childcount = tree[8]
			local children_encountered = 0

			for i=0,7 do
				local c = tree[i]
				if c then
					children_encountered=children_encountered+1

					local cmins = mins

					if bit.band(i,1) then cmins.x=center.x end
					if bit.band(i,2) then cmins.y=center.y end
					if bit.band(i,4) then cmins.z=center.z end

					oct_render_r(tree[i],cmins,width)

					if children_encountered==childcount then break end
				end
			end
		end
	end

	function ENT:Draw()
		//local t = SysTime()

		render.SetMaterial(atlas)

		local matrix = Matrix()
		matrix:Translate(self:GetPos())

		render.SuppressEngineLighting(true)
		render.OverrideDepthEnable(true,true)
		cam.PushModelMatrix(matrix)
		if self.blur_textures then
			render.PushFilterMag(TEXFILTER.LINEAR)
			render.PushFilterMin(TEXFILTER.LINEAR)
		end
		
		local vx,vy,vz = self:GetChunkPos(LocalPlayer():GetPos())
		local render_dist = self.render_dist

		for x=math.max(0,math.floor((vx-render_dist)/16)),math.min(math.floor((vx+render_dist)/16),4) do
			for y=math.max(0,math.floor((vy-render_dist)/16)),math.min(math.floor((vy+render_dist)/16),4) do
				for z=math.max(0,math.floor((vz-render_dist)/16)),math.min(math.floor((vz+render_dist)/16),4) do
					local tree = self.chunk_octrees[x+y*5+z*25]
					if tree then oct_render_r(tree,Vector(-16000+x*6400,-16000+y*6400,-16000+z*6400),16) end
				end
			end
		end

		render.SuppressEngineLighting(false)
		render.OverrideDepthEnable(false)
		cam.PopModelMatrix()
		if self.blur_textures then
			render.PopFilterMag()
			render.PopFilterMin()
		end

		//print((SysTime()-t)*1000)
	end
end

function ENT:GetData(x,y,z)
	local d = self.voxels[x+y*800+z*640000]
	if !d then
		local depth= self.default_heightmap:GetColor(x,y).r-z
		//TODO allow specification of function to get default value
		if depth<=0 then return 0 end
		if depth==1 then return 1 end
		if depth<5 then return 2 end
		return 3
	end
end

function ENT:GetChunkPos(v)
	v=(v+Vector(16000,16000,16000))/400
	return math.floor(v.x),math.floor(v.y),math.floor(v.z)
end

//For testing.
function ENT:SpawnFunction( ply, tr, ClassName )
	local SpawnPos = Vector(-15980,-15980,-15980)

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()

	ply:SetPos(SpawnPos+Vector(100,100,100))
	
	return ent
end