"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FriendsRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let FriendsRepository = class FriendsRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findFriendshipById(id) {
        return this.prisma.friendships.findUnique({
            where: { id },
        });
    }
    async findFriendshipBetweenUsers(userAId, userBId) {
        return this.prisma.friendships.findFirst({
            where: {
                OR: [
                    { requester_id: userAId, addressee_id: userBId },
                    { requester_id: userBId, addressee_id: userAId },
                ],
            },
        });
    }
    async createFriendRequest(requesterId, addresseeId) {
        return this.prisma.friendships.upsert({
            where: {
                requester_id_addressee_id: {
                    requester_id: requesterId,
                    addressee_id: addresseeId,
                },
            },
            create: {
                requester_id: requesterId,
                addressee_id: addresseeId,
                status: 'pending',
            },
            update: {
                status: 'pending',
            },
        });
    }
    async updateFriendshipStatus(id, status) {
        return this.prisma.friendships.update({
            where: { id },
            data: { status },
        });
    }
    async listAcceptedFriendshipsForUser(userId) {
        return this.prisma.friendships.findMany({
            where: {
                status: 'accepted',
                OR: [{ requester_id: userId }, { addressee_id: userId }],
            },
            include: {
                requester: true,
                addressee: true,
            },
        });
    }
    async listIncomingRequests(userId) {
        return this.prisma.friendships.findMany({
            where: {
                status: 'pending',
                addressee_id: userId,
            },
            include: {
                requester: true,
            },
        });
    }
    async listOutgoingRequests(userId) {
        return this.prisma.friendships.findMany({
            where: {
                status: 'pending',
                requester_id: userId,
            },
            include: {
                addressee: true,
            },
        });
    }
};
exports.FriendsRepository = FriendsRepository;
exports.FriendsRepository = FriendsRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], FriendsRepository);
//# sourceMappingURL=friends.repository.js.map